param(
    [Alias("i")]
    [int[]]$Id,

    [Alias("n")]
    [string[]]$Name,

    [string]$Root,

    [string]$OutputRoot
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Default paths
# ------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = "C:\BC\SI-AL-NEW"
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = "C:\AL-TMP"
}

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------

if (-not $Id -and -not $Name) {
    Write-Host ""
    Write-Host "Specify at least one search parameter:" -ForegroundColor Yellow
    Write-Host '  -i 59052,59062'
    Write-Host '  -n "SI WB Inbound Job","SI WB Inbound Processor"'
    Write-Host ""
    exit 1
}

if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    Write-Error "Project root does not exist: $Root"
    exit 1
}

# Normalize paths
$Root = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')

# ------------------------------------------------------------
# Output directory
# ------------------------------------------------------------

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$OutputDir = Join-Path $OutputRoot $Timestamp

New-Item `
    -ItemType Directory `
    -Path $OutputDir `
    -Force | Out-Null

Write-Host ""
Write-Host "AL Object Finder" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host "Root:   $Root"
Write-Host "Output: $OutputDir"
Write-Host ""

if ($Id) {
    Write-Host "IDs:    $($Id -join ', ')"
}

if ($Name) {
    Write-Host "Names:  $($Name -join ', ')"
}

Write-Host ""
Write-Host "Scanning AL files..." -ForegroundColor DarkGray

# ------------------------------------------------------------
# Prepare search collections
# ------------------------------------------------------------

$RequestedIds = @{}

foreach ($ObjectId in $Id) {
    $RequestedIds[$ObjectId] = $false
}

$RequestedNames = @{}

foreach ($ObjectName in $Name) {

    if ([string]::IsNullOrWhiteSpace($ObjectName)) {
        continue
    }

    $NameKey = $ObjectName.Trim().ToLowerInvariant()

    $RequestedNames[$NameKey] = @{
        Original = $ObjectName.Trim()
        Found    = $false
    }
}

$Matches = @()

# ------------------------------------------------------------
# AL object declaration pattern
#
# Supported examples:
#
# table 59000 "SI Weighing"
# tableextension 59010 "SI Item Ext." extends Item
# page 59001 "SI Weighing Record"
# pageextension 59011 "SI Item Card Ext." extends "Item Card"
# codeunit 59052 "SI WB Inbound Job"
# report 59070 "SI Something"
# query 59080 "SI Something"
# xmlport 59090 "SI Something"
# enum 59100 "SI Something"
# enumextension 59101 "SI Something Ext." extends "SI Something"
# permissionset 59110 "SI SOMETHING"
#
# ------------------------------------------------------------

$ObjectPattern = '(?im)^\s*(table|tableextension|page|pageextension|codeunit|report|query|xmlport|enum|enumextension|interface|permissionset|permissionsetextension|profile|controladdin)\s+(\d+)\s+(?:"([^"]+)"|([^\s{]+))'

# ------------------------------------------------------------
# Get all AL files
# ------------------------------------------------------------

$ALFiles = @(
    Get-ChildItem `
        -LiteralPath $Root `
        -Filter "*.al" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue
)

Write-Host "AL files found: $($ALFiles.Count)" -ForegroundColor DarkGray

# ------------------------------------------------------------
# Scan files
# ------------------------------------------------------------

foreach ($File in $ALFiles) {

    try {
        $Content = Get-Content `
            -LiteralPath $File.FullName `
            -Raw `
            -Encoding UTF8 `
            -ErrorAction Stop
    }
    catch {
        Write-Warning "Cannot read: $($File.FullName)"
        continue
    }

    # Empty .al files return $null.
    # Regex.Match cannot accept a null input.
    if ([string]::IsNullOrWhiteSpace($Content)) {
        continue
    }

    $Match = [regex]::Match($Content, $ObjectPattern)

    if (-not $Match.Success) {
        continue
    }

    $ObjectType = $Match.Groups[1].Value
    $ObjectId   = [int]$Match.Groups[2].Value

    if ($Match.Groups[3].Success) {
        $ObjectName = $Match.Groups[3].Value
    }
    else {
        $ObjectName = $Match.Groups[4].Value
    }

    $MatchedBy = @()

    # --------------------------------------------------------
    # Search by ID
    # --------------------------------------------------------

    if ($RequestedIds.ContainsKey($ObjectId)) {
        $RequestedIds[$ObjectId] = $true
        $MatchedBy += "ID"
    }

    # --------------------------------------------------------
    # Search by exact object name, case-insensitive
    # --------------------------------------------------------

    $NameKey = $ObjectName.ToLowerInvariant()

    if ($RequestedNames.ContainsKey($NameKey)) {
        $RequestedNames[$NameKey].Found = $true
        $MatchedBy += "Name"
    }

    # Nothing requested matched this object
    if ($MatchedBy.Count -eq 0) {
        continue
    }

    # --------------------------------------------------------
    # Preserve directory structure relative to project root
    # --------------------------------------------------------

    $RelativePath = $File.FullName.Substring($Root.Length).TrimStart('\')

    $DestinationFile = Join-Path `
        $OutputDir `
        $RelativePath

    $DestinationDirectory = Split-Path `
        $DestinationFile `
        -Parent

    if (-not (Test-Path -LiteralPath $DestinationDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $DestinationDirectory `
            -Force | Out-Null
    }

    # --------------------------------------------------------
    # Copy matched AL file
    # --------------------------------------------------------

    Copy-Item `
        -LiteralPath $File.FullName `
        -Destination $DestinationFile `
        -Force

    # --------------------------------------------------------
    # Register result
    # --------------------------------------------------------

    $Matches += [PSCustomObject]@{
        Type      = $ObjectType
        ID        = $ObjectId
        Name      = $ObjectName
        MatchedBy = ($MatchedBy -join "+")
        Source    = $RelativePath
    }
}

# ------------------------------------------------------------
# Results
# ------------------------------------------------------------

Write-Host ""

if ($Matches.Count -gt 0) {

    Write-Host "Found and copied:" -ForegroundColor Green
    Write-Host ""

    $Matches |
        Sort-Object Type, ID, Name |
        Format-Table `
            @{Label="Type";   Expression={$_.Type}},
            @{Label="ID";     Expression={$_.ID}},
            @{Label="Name";   Expression={$_.Name}},
            @{Label="By";     Expression={$_.MatchedBy}},
            @{Label="Source"; Expression={$_.Source}} `
            -AutoSize
}
else {
    Write-Host "No matching AL objects found." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Missing IDs
# ------------------------------------------------------------

$MissingIds = @(
    foreach ($Key in $RequestedIds.Keys) {

        if (-not $RequestedIds[$Key]) {
            $Key
        }
    }
)

if ($MissingIds.Count -gt 0) {

    Write-Host ""
    Write-Host "IDs not found:" -ForegroundColor Yellow

    foreach ($MissingId in ($MissingIds | Sort-Object)) {
        Write-Host "  $MissingId"
    }
}

# ------------------------------------------------------------
# Missing names
# ------------------------------------------------------------

$MissingNames = @(
    foreach ($Key in $RequestedNames.Keys) {

        if (-not $RequestedNames[$Key].Found) {
            $RequestedNames[$Key].Original
        }
    }
)

if ($MissingNames.Count -gt 0) {

    Write-Host ""
    Write-Host "Names not found:" -ForegroundColor Yellow

    foreach ($MissingName in ($MissingNames | Sort-Object)) {
        Write-Host "  $MissingName"
    }
}

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "Matched objects: $($Matches.Count)"
Write-Host "Copied to:       $OutputDir" -ForegroundColor Cyan
Write-Host ""