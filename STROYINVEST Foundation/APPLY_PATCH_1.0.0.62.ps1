param(
    [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"

$obsolete = @(
    "src\OrganizationalIdentity\Tables\SIUserEmployeeLink.Table.al",
    "src\OrganizationalIdentity\Pages\SIUserEmployeeLinks.Page.al"
)

foreach ($relativePath in $obsolete) {
    $path = Join-Path $ProjectRoot $relativePath
    if (Test-Path $path) {
        Remove-Item $path -Force
        Write-Host "Removed legacy file: $relativePath"
    }
}

Write-Host "Legacy Organizational Identity source cleanup completed."
