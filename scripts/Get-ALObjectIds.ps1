#requires -Version 5.1
<#
.SYNOPSIS
  Inventory and validate AL object IDs per Business Central extension (app.json).
.DESCRIPTION
  Read-only source inspection. Writes UTF-8 JSON and TXT reports to a selected output folder.
  Does not reserve IDs or change source/manifests. Not a substitute for the AL compiler.
.EXAMPLE
  powershell.exe -NoProfile -File .\scripts\Get-ALObjectIds.ps1 -RootPath 'C:\BC\SI-AL-NEW'
.EXAMPLE
  pwsh -NoProfile -File .\scripts\Get-ALObjectIds.ps1 -RootPath 'C:\BC\SI-AL-NEW' -AppName 'STROYINVEST Foundation'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)][string]$RootPath = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputDirectory = '',
    [string]$AppName = '',
    [Nullable[int]]$RangeFrom = $null,
    [Nullable[int]]$RangeTo = $null,
    [switch]$NoFiles,
    [switch]$Strict
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Prop($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) { return $null }
    return $prop.Value
}
function Add-Issue([string]$Severity, [string]$Code, [string]$Message, [string]$App = '', [string]$File = '') {
    $script:issues.Add([pscustomobject]@{ severity=$Severity; code=$Code; message=$Message; app=$App; file=$File })
}
function Get-Relative([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    $prefix = $script:root.TrimEnd([char]'\',[char]'/') + [IO.Path]::DirectorySeparatorChar
    if ($full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { return $full.Substring($prefix.Length).Replace('\','/') }
    if ($full -eq $script:root) { return '.' }
    return $full.Replace('\','/')
}
function Is-Excluded([string]$Path) {
    return ($Path -match '(?i)[\\/](\.git|\.alpackages|\.vscode|node_modules|bin|obj|dist|build|\.next|reports)[\\/]')
}
function Get-FreeGaps([int]$Start, [int]$End, [int[]]$Used) {
    $gaps = New-Object 'System.Collections.Generic.List[object]'
    $sorted = @($Used | Where-Object { $_ -ge $Start -and $_ -le $End } | Sort-Object -Unique)
    $next = [long]$Start
    foreach ($id in $sorted) {
        if ([long]$id -gt $next) { $gaps.Add([pscustomobject]@{ from=[int]$next; to=[int]([long]$id-1) }) }
        $next = [long]$id + 1
    }
    if ($next -le [long]$End) { $gaps.Add([pscustomobject]@{ from=[int]$next; to=$End }) }
    return @($gaps.ToArray())
}

$root = [IO.Path]::GetFullPath($RootPath)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Repository root not found: $root" }
if (($null -ne $RangeFrom) -xor ($null -ne $RangeTo)) { throw 'Specify both -RangeFrom and -RangeTo, or neither.' }
if ($null -ne $RangeFrom -and ($RangeFrom -lt 0 -or $RangeTo -lt $RangeFrom)) { throw 'Invalid optional range.' }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $root 'reports/al-object-ids' }
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $NoFiles -and -not (Test-Path -LiteralPath $output)) { New-Item -Path $output -ItemType Directory -Force | Out-Null }
$issues = New-Object 'System.Collections.Generic.List[object]'
$objects = New-Object 'System.Collections.Generic.List[object]'
$apps = New-Object 'System.Collections.Generic.List[object]'

# Discover app.json by file name, not by folder prefix. Skip generated/archived trees.
$manifests = @(Get-ChildItem -LiteralPath $root -Filter 'app.json' -File -Recurse | Where-Object { -not (Is-Excluded $_.FullName) } | Sort-Object FullName)
foreach ($manifest in $manifests) {
    $dir = $manifest.Directory.FullName
    $rel = Get-Relative $manifest.FullName
    try {
        $raw = Get-Content -LiteralPath $manifest.FullName -Raw -Encoding UTF8
        $meta = ConvertFrom-Json -InputObject $raw
    } catch {
        Add-Issue 'error' 'MANIFEST_INVALID' "Cannot parse app.json: $($_.Exception.Message)" '' $rel
        continue
    }
    $name = [string](Get-Prop $meta 'name')
    $guid = [string](Get-Prop $meta 'id')
    if (-not $name -or -not $guid) {
        Add-Issue 'warning' 'MANIFEST_INCOMPLETE' 'app.json lacks name or id; treating as a possible extension.' $name $rel
    }
    if ($AppName -and $name -notlike "*$AppName*") { continue }
    $ranges = New-Object 'System.Collections.Generic.List[object]'
    foreach ($r in @(Get-Prop $meta 'idRanges')) {
        if ($null -eq $r) { continue }
        $from = Get-Prop $r 'from'; $to = Get-Prop $r 'to'
        if ($null -eq $from -or $null -eq $to -or [long]$from -lt 0 -or [long]$to -lt [long]$from -or [long]$to -gt [int]::MaxValue) {
            Add-Issue 'error' 'INVALID_ID_RANGE' "Invalid idRanges entry in $rel" $name $rel
            continue
        }
        $ranges.Add([pscustomobject]@{ from=[int]$from; to=[int]$to })
    }
    if ($ranges.Count -eq 0) { Add-Issue 'warning' 'NO_ID_RANGES' 'No valid idRanges in manifest; allowed IDs cannot be established.' $name $rel }
    $apps.Add([pscustomobject]@{
        name=$name; appId=$guid; version=[string](Get-Prop $meta 'version');
        manifest=$rel; directory=$dir; ranges=@($ranges.ToArray()); objects=@(); freeRanges=@();
        summary=$null
    })
}
if ($apps.Count -eq 0) { Add-Issue 'error' 'NO_APPS' 'No matching app.json files were discovered.' }

# Match declarations at start of a line. Lexical states prevent comment markers
# inside AL single-quoted text literals or double-quoted identifiers from being
# mistaken for actual comments. This is not a complete AL compiler.
$declaration = '^\s*(tableextension|pageextension|enumextension|permissionsetextension|table|page|codeunit|report|query|xmlport|enum|interface|permissionset|profile|controladdin|controladd-in|entitlement)\s+(\d+)\s+(?:"((?:[^"]|"")+)"|([^\s{]+))'
foreach ($app in $apps) {
    $files = @(Get-ChildItem -LiteralPath $app.directory -Filter '*.al' -File -Recurse | Where-Object { -not (Is-Excluded $_.FullName) } | Sort-Object FullName)
    foreach ($file in $files) {
        $lineNo = 0
        $blockComment = $false
        $inTextLiteral = $false
        $inQuotedIdentifier = $false
        foreach ($line in [IO.File]::ReadLines($file.FullName)) {
            $lineNo++
            # AL text literals use single quotes and escape apostrophes as ''.
            # Quoted identifiers use double quotes and escape quotes as "".
            # Neither may be treated as an AL comment. Preserve identifier text
            # for the declaration matcher; mask text literals to prevent false matches.
            $clean = New-Object System.Text.StringBuilder
            for ($i = 0; $i -lt $line.Length; $i++) {
                $ch = $line[$i]
                $next = if ($i + 1 -lt $line.Length) { $line[$i + 1] } else { [char]0 }

                if ($blockComment) {
                    if ($ch -eq '*' -and $next -eq '/') {
                        $blockComment = $false
                        $i++
                    }
                    continue
                }
                if ($inTextLiteral) {
                    if ($ch -eq "'") {
                        if ($next -eq "'") { $i++ } # Escaped apostrophe
                        else { $inTextLiteral = $false }
                    }
                    [void]$clean.Append(' ')
                    continue
                }
                if ($inQuotedIdentifier) {
                    [void]$clean.Append($ch)
                    if ($ch -eq '"') {
                        if ($next -eq '"') {
                            [void]$clean.Append($next)
                            $i++
                        } else {
                            $inQuotedIdentifier = $false
                        }
                    }
                    continue
                }
                if ($ch -eq '/' -and $next -eq '/') { break }
                if ($ch -eq '/' -and $next -eq '*') {
                    $blockComment = $true
                    $i++
                    continue
                }
                if ($ch -eq "'") {
                    $inTextLiteral = $true
                    [void]$clean.Append(' ')
                    continue
                }
                if ($ch -eq '"') {
                    $inQuotedIdentifier = $true
                    [void]$clean.Append($ch)
                    continue
                }
                [void]$clean.Append($ch)
            }
            $m = [regex]::Match($clean.ToString(), $declaration, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($m.Success) {
                $type = $m.Groups[1].Value.ToLowerInvariant()
                $name = if ($m.Groups[3].Success) { $m.Groups[3].Value.Replace('""','"') } else { $m.Groups[4].Value }
                $id = [int]$m.Groups[2].Value
                $allowed = $false
                foreach ($range in $app.ranges) { if ($id -ge $range.from -and $id -le $range.to) { $allowed=$true; break } }
                $item = [pscustomobject]@{
                    app=$app.name; appId=$app.appId; type=$type; id=$id; name=$name;
                    file=(Get-Relative $file.FullName); line=$lineNo; withinManifestRange=$allowed
                }
                $objects.Add($item)
                if (-not $allowed -and $app.ranges.Count -gt 0) {
                    Add-Issue 'error' 'OUT_OF_RANGE' "$type $id is outside app.json idRanges" $app.name $item.file
                }
            }
        }
        if ($inTextLiteral) { Add-Issue 'warning' 'UNCLOSED_TEXT_LITERAL' 'Unclosed single-quoted AL text literal; check parser results.' $app.name (Get-Relative $file.FullName) }
        if ($inQuotedIdentifier) { Add-Issue 'warning' 'UNCLOSED_QUOTED_IDENTIFIER' 'Unclosed double-quoted AL identifier; check parser results.' $app.name (Get-Relative $file.FullName) }
        if ($blockComment) { Add-Issue 'warning' 'UNCLOSED_BLOCK_COMMENT' 'Unclosed /* comment; check parser results.' $app.name (Get-Relative $file.FullName) }
    }
}

# Duplicate identity is (app ID, object type, object ID), not numeric ID alone.
foreach ($group in @($objects | Group-Object { "$($_.appId)|$($_.type)|$($_.id)" } | Where-Object Count -gt 1)) {
    $example = $group.Group[0]
    $locations = ($group.Group | ForEach-Object { "$($_.file):$($_.line)" }) -join ', '
    Add-Issue 'error' 'DUPLICATE_OBJECT' "Duplicate $($example.type) $($example.id): $locations" $example.app $example.file
}

# Free IDs are advisory: they are not reserved, and other apps/dependencies may impose constraints.
foreach ($app in $apps) {
    $owned = @($objects | Where-Object { $_.appId -eq $app.appId })
    $app.objects = @($owned | Sort-Object id,type,file)
    $free = New-Object 'System.Collections.Generic.List[object]'
    foreach ($range in $app.ranges) {
        $used = @($owned | Where-Object { $_.id -ge $range.from -and $_.id -le $range.to } | ForEach-Object { $_.id })
        foreach ($gap in @(Get-FreeGaps $range.from $range.to $used)) {
            if ($null -ne $RangeFrom -and ($gap.to -lt $RangeFrom -or $gap.from -gt $RangeTo)) { continue }
            if ($null -ne $RangeFrom) { $gap = [pscustomobject]@{ from=[math]::Max($gap.from,$RangeFrom); to=[math]::Min($gap.to,$RangeTo) } }
            $free.Add($gap)
        }
    }
    $app.freeRanges = @($free.ToArray())
    $app.summary = [pscustomobject]@{
        objectCount=$owned.Count;
        outOfRangeCount=@($owned | Where-Object { -not $_.withinManifestRange }).Count;
        nextCandidateId=if ($free.Count -gt 0) { $free[0].from } else { $null }
    }
}

$errors = @($issues | Where-Object severity -eq 'error').Count
$warnings = @($issues | Where-Object severity -eq 'warning').Count
$result = [ordered]@{
    schemaVersion='2.0'; generatedAtUtc=[DateTime]::UtcNow.ToString('o');
    rootPath=$root; parser='line-based AL declaration scan (not a compiler)';
    status=if ($errors -gt 0) { 'errors' } elseif ($warnings -gt 0) { 'warnings' } else { 'ok' };
    summary=[ordered]@{ appCount=$apps.Count; objectCount=$objects.Count; errorCount=$errors; warningCount=$warnings };
    apps=@($apps | ForEach-Object { [ordered]@{ name=$_.name; appId=$_.appId; version=$_.version; manifest=$_.manifest; idRanges=$_.ranges; summary=$_.summary; freeRanges=$_.freeRanges } });
    objects=@($objects | Sort-Object app,type,id,file);
    issues=@($issues.ToArray());
    limitations=@('Advisory inventory only; AL compiler and approved ID allocations remain authoritative.', 'Free IDs are not reservations.', 'Field IDs, enum values, dependencies and published apps are not scanned.', 'Parser does not implement full AL grammar; verify unusual declarations and conditional compilation.')
}
$json = ConvertTo-Json -InputObject $result -Depth 12
$lines = New-Object 'System.Collections.Generic.List[string]'
$lines.Add('AL OBJECT ID INVENTORY (v2)')
$lines.Add("Generated UTC: $($result.generatedAtUtc)")
$lines.Add("Repository: $root")
$lines.Add("Status: $($result.status) | Apps: $($apps.Count) | Objects: $($objects.Count) | Errors: $errors | Warnings: $warnings")
$lines.Add('')
foreach ($app in $apps) {
    $lines.Add("APP: $($app.name) | $($app.appId) | v$($app.version)")
    $lines.Add("Manifest: $($app.manifest)")
    $lines.Add("Allowed ranges: $(if ($app.ranges.Count) { ($app.ranges | ForEach-Object { "$($_.from)-$($_.to)" }) -join ', ' } else { '(none)' })")
    $lines.Add("Objects: $($app.summary.objectCount) | Out of range: $($app.summary.outOfRangeCount) | Next candidate: $($app.summary.nextCandidateId)")
    $lines.Add("Free gaps: $(if ($app.freeRanges.Count) { ($app.freeRanges | ForEach-Object { if ($_.from -eq $_.to) { "$($_.from)" } else { "$($_.from)-$($_.to)" } }) -join ', ' } else { '(none)' })")
    $lines.Add('')
}
$lines.Add('ISSUES:')
if ($issues.Count -eq 0) { $lines.Add('None') }
foreach ($issue in $issues) { $lines.Add("[$($issue.severity.ToUpperInvariant())] $($issue.code) | $($issue.app) | $($issue.file) | $($issue.message)") }
$lines.Add('')
$lines.Add('Object details are in AL-Object-IDs.json (objects array).')
$lines.Add('Free gaps are advisory and not reserved. Validate against source, dependencies, and AL compiler.')
if (-not $NoFiles) {
    # Write temporary files first, then replace reports. Reports are generated outputs only.
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $jsonPath = Join-Path $output 'AL-Object-IDs.json'
    $txtPath = Join-Path $output 'AL-Object-IDs.txt'
    [IO.File]::WriteAllText($jsonPath + '.tmp', $json, $utf8)
    [IO.File]::WriteAllLines($txtPath + '.tmp', [string[]]$lines.ToArray(), $utf8)
    Move-Item -LiteralPath ($jsonPath + '.tmp') -Destination $jsonPath -Force
    Move-Item -LiteralPath ($txtPath + '.tmp') -Destination $txtPath -Force
    Write-Host "JSON: $jsonPath"
    Write-Host "TXT:  $txtPath"
} else { $lines | Write-Output }
Write-Host "Inventory: $($result.status); apps=$($apps.Count); objects=$($objects.Count); errors=$errors; warnings=$warnings"
if ($Strict -and $errors -gt 0) { exit 2 }
