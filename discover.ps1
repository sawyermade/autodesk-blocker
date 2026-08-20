# Scans common Windows locations for Autodesk-related install/data
# directories (Program Files, Program Files (x86), ProgramData, and every
# user profile's AppData Roaming + Local) and reports what it finds, with
# a recursive .exe count for each. Writes the plain list of paths (one per
# line, no exe counts) to block-list.txt next to this script, which
# block-list.bat reads. Re-running this overwrites block-list.txt, so
# move any manually-added lines elsewhere before re-running if you want
# to keep them.

$roots = New-Object System.Collections.Generic.List[string]

foreach ($p in @(
    $env:ProgramFiles,
    ${env:ProgramFiles(x86)},
    $env:ProgramData,
    $env:CommonProgramFiles,
    ${env:CommonProgramFiles(x86)}
)) {
    if ($p) { $roots.Add($p) }
}

Get-ChildItem -LiteralPath 'C:\Users' -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $roots.Add((Join-Path $_.FullName 'AppData\Roaming'))
    $roots.Add((Join-Path $_.FullName 'AppData\Local'))
}

$matches = foreach ($root in $roots) {
    if (Test-Path -LiteralPath $root) {
        Get-ChildItem -LiteralPath $root -Directory -Force -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'Autodesk|ADSK' }
    }
}

$paths = $matches | Select-Object -ExpandProperty FullName -Unique | Sort-Object

$outFile = Join-Path $PSScriptRoot 'block-list.txt'
# Windows PowerShell 5.1's -Encoding UTF8 writes a BOM, which cmd's
# `for /f` in block-list.bat does not strip -- it corrupts the first
# line of the file. Write plain UTF-8 without a BOM instead.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not $paths) {
    Write-Host 'No Autodesk-related directories found.'
    [System.IO.File]::WriteAllLines($outFile, [string[]]@(), $utf8NoBom)
    return
}

Write-Host "Found $($paths.Count) Autodesk-related director$(if ($paths.Count -eq 1) {'y'} else {'ies'}):"
Write-Host ''

foreach ($path in $paths) {
    $exeCount = (Get-ChildItem -LiteralPath $path -Recurse -Force -File -Filter *.exe -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host ("  {0}  [{1} .exe file(s)]" -f $path, $exeCount)
}

[System.IO.File]::WriteAllLines($outFile, [string[]]$paths, $utf8NoBom)

Write-Host ''
Write-Host "Wrote $($paths.Count) path(s) to $outFile"
Write-Host 'Edit that file to add/remove directories, then run block-list.bat.'
