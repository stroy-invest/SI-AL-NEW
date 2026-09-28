param(
    [string]$RootPath = "C:\BC\SI-AL",
    [int]$RangeFrom = 52000,
    [int]$RangeTo = 52999
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $RootPath)) {
    throw "Root path not found: $RootPath"
}

$objectRegex = '^\s*(table|tableextension|page|pageextension|codeunit|report|query|xmlport|enum|enumextension|interface|permissionset|permissionsetextension|profile|controladdin)\s+(\d+)\s+"?([^"]*)"?'

$targetDirs = Get-ChildItem -Path $RootPath -Directory -Recurse |
    Where-Object {
        $_.Name -like "SI-*" -or $_.Name -like "STROYINVEST*"
    }

$alFiles = foreach ($dir in $targetDirs) {
    Get-ChildItem -Path $dir.FullName -Filter "*.al" -File -Recurse
}

$objects = foreach ($file in $alFiles) {
    $lineNo = 0

    Get-Content $file.FullName | ForEach-Object {
        $lineNo++

        if ($_ -match $objectRegex) {
            [PSCustomObject]@{
                ID       = [int]$matches[2]
                Type     = $matches[1]
                Name     = $matches[3].Trim()
                File     = $file.FullName.Replace($RootPath, "").TrimStart("\")
                Line     = $lineNo
            }
        }
    }
}

$objects = $objects | Sort-Object ID, Type, Name

Write-Host ""
Write-Host "AL object IDs in project: $RootPath"
Write-Host "Scanned folders: SI-* and STROYINVEST*"
Write-Host "Range: $RangeFrom..$RangeTo"
Write-Host ""

$objects | Format-Table ID, Type, Name, File, Line -AutoSize

$occupiedInRange = $objects | Where-Object {
    $_.ID -ge $RangeFrom -and $_.ID -le $RangeTo
}

$usedIds = $occupiedInRange.ID | Sort-Object -Unique
$allIds = $RangeFrom..$RangeTo
$freeIds = $allIds | Where-Object { $_ -notin $usedIds }

Write-Host ""
Write-Host "Summary"
Write-Host "-------"
Write-Host "Objects found:       $($objects.Count)"
Write-Host "Objects in range:    $($occupiedInRange.Count)"
Write-Host "Unique IDs in range: $($usedIds.Count)"

if ($usedIds.Count -gt 0) {
    Write-Host "Minimum used ID:     $($usedIds[0])"
    Write-Host "Maximum used ID:     $($usedIds[-1])"
} else {
    Write-Host "Minimum used ID:     none"
    Write-Host "Maximum used ID:     none"
}

if ($freeIds.Count -gt 0) {
    Write-Host "Next free ID:        $($freeIds[0])"
} else {
    Write-Host "Next free ID:        none"
}

$duplicates = $objects |
    Group-Object ID |
    Where-Object { $_.Count -gt 1 }

if ($duplicates.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Duplicate object IDs found"
    Write-Host "-----------------------------------"

    foreach ($group in $duplicates) {
        Write-Host ""
        Write-Host "ID $($group.Name):"
        $group.Group | Format-Table Type, Name, File, Line -AutoSize
    }
}

Write-Host ""
Write-Host "Free gaps"
Write-Host "---------"

if ($freeIds.Count -eq 0) {
    Write-Host "No free IDs in range."
} else {
    $gapStart = $freeIds[0]
    $prev = $freeIds[0]

    for ($i = 1; $i -lt $freeIds.Count; $i++) {
        $current = $freeIds[$i]

        if ($current -ne ($prev + 1)) {
            if ($gapStart -eq $prev) {
                Write-Host "$gapStart"
            } else {
                Write-Host "$gapStart-$prev"
            }

            $gapStart = $current
        }

        $prev = $current
    }

    if ($gapStart -eq $prev) {
        Write-Host "$gapStart"
    } else {
        Write-Host "$gapStart-$prev"
    }
}