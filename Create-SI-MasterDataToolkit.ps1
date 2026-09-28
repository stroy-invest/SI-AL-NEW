# ============================================================
# SI Master Data Toolkit
# Minimal AL project structure
# ============================================================

[CmdletBinding()]
param(
    [string]$ProjectRoot = "C:\BC\SI-AL\SI-MasterDataToolkit"
)

$ErrorActionPreference = "Stop"

function New-DirectoryIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item `
            -ItemType Directory `
            -Path $Path `
            -Force | Out-Null

        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function New-FileIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$Content = ""
    )

    $parentDirectory = Split-Path -Parent $Path

    if ($parentDirectory) {
        New-DirectoryIfMissing -Path $parentDirectory
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        Set-Content `
            -LiteralPath $Path `
            -Value $Content `
            -Encoding UTF8

        Write-Host "[CREATED] $Path" -ForegroundColor Cyan
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Creating minimal SI Master Data Toolkit AL structure..." `
    -ForegroundColor Yellow
Write-Host "Root: $ProjectRoot" -ForegroundColor Yellow
Write-Host ""

# ------------------------------------------------------------
# Directories
# ------------------------------------------------------------

$directories = @(
    "src",
    "src\Enums",
    "src\Tables",
    "src\TableExtensions",
    "src\Pages",
    "src\PageExtensions",
    "src\Codeunits",
    "src\Permissions"
)

foreach ($directory in $directories) {
    New-DirectoryIfMissing `
        -Path (Join-Path $ProjectRoot $directory)
}

# ------------------------------------------------------------
# .gitignore
# ------------------------------------------------------------

$gitIgnoreContent = @'
# Business Central AL
.alpackages/
.snapshots/
.output/
.packagecache/

# Generated AL packages
*.app

# VS Code
.vscode/settings.json
.vscode/.alcache/

# User and local files
*.user
*.tmp
*.log

# Operating system files
.DS_Store
Thumbs.db
desktop.ini
'@

New-FileIfMissing `
    -Path (Join-Path $ProjectRoot ".gitignore") `
    -Content $gitIgnoreContent

# ------------------------------------------------------------
# README
# ------------------------------------------------------------

$readmeContent = @'
# SI Master Data Toolkit

Minimal Business Central AL extension for controlled management of:

- Units of Measure;
- numeric Item Attribute UoM;
- package types;
- item and item variant packages.

## Pilot scope

1. Extend standard Unit of Measure.
2. Add Symbol, Measurement System, UoM Kind and Blocked.
3. Support simple Scaled UoM.
4. Support structured Derived UoM.
5. Add controlled UoM Code to Item Attribute.
6. Synchronize the standard text Unit of Measure field.
7. Provide a one-time Item Attribute UoM migration utility.
8. Add SI Package Type.
9. Add SI Item Package.
10. Add basic pages, page extensions and validations.

The application does not implement a universal physical quantity or
unit-conversion engine.
'@

New-FileIfMissing `
    -Path (Join-Path $ProjectRoot "README.md") `
    -Content $readmeContent

# ------------------------------------------------------------
# Optional placeholder files
# ------------------------------------------------------------

$placeholderFiles = @(
    "src\Enums\.gitkeep",
    "src\Tables\.gitkeep",
    "src\TableExtensions\.gitkeep",
    "src\Pages\.gitkeep",
    "src\PageExtensions\.gitkeep",
    "src\Codeunits\.gitkeep",
    "src\Permissions\.gitkeep"
)

foreach ($file in $placeholderFiles) {
    New-FileIfMissing `
        -Path (Join-Path $ProjectRoot $file)
}

Write-Host ""
Write-Host "Minimal AL project structure created successfully." `
    -ForegroundColor Green
Write-Host ""
Write-Host "Result:" -ForegroundColor Yellow
Write-Host ""
Write-Host "SI-MasterDataToolkit"
Write-Host "  src"
Write-Host "    Enums"
Write-Host "    Tables"
Write-Host "    TableExtensions"
Write-Host "    Pages"
Write-Host "    PageExtensions"
Write-Host "    Codeunits"
Write-Host "    Permissions"
Write-Host ""