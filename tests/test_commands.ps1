$ErrorActionPreference = 'Stop'
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'vwt.psm1') -Force -DisableNameChecking
$module = Get-Module vwt
$original = Get-Location
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('vwt_commands_' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
$script:checks = 0
function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    $script:checks++
}
function OutputOf([scriptblock]$Action) { (& $Action 6>&1) | Out-String }
try {
    Set-Location -LiteralPath $testRoot
    $file = Join-Path $testRoot 'Tiếng Việt [1].txt'
    [IO.File]::WriteAllText($file, "Một hai`nBa bốn`nNăm sáu", [Text.Encoding]::UTF8)
    Assert ((@(dau $file 1) -join '') -eq 'Một hai') 'First line wrong'
    Assert ((@(cuoi $file 1) -join '') -eq 'Năm sáu') 'Last line wrong'
    Assert ((@(dau $file)).Count -eq 3) 'Default line count wrong'
    Assert ((OutputOf { dau $file 0 }).Contains('[Lỗi]')) 'Invalid line count allowed'
    Assert ((OutputOf { cuoi 'missing.txt' }).Contains('[Lỗi]')) 'Missing file not reported'
    Assert ((OutputOf { dem $file }).Contains('3 dòng, 6 từ')) 'Word/line count wrong'
    [IO.File]::WriteAllText((Join-Path $testRoot 'empty.txt'), '')
    Assert ((OutputOf { dem 'empty.txt' }).Contains('0 dòng, 0 từ')) 'Empty file count wrong'
    [IO.Directory]::CreateDirectory((Join-Path $testRoot 'Thư mục')) | Out-Null
    doiten $file 'Đã đổi [2].txt'
    $renamed = Join-Path $testRoot 'Đã đổi [2].txt'
    Assert ([IO.File]::Exists($renamed) -and -not [IO.File]::Exists($file)) 'Rename failed'
    Assert ((OutputOf { doiten $renamed 'empty.txt' }).Contains('[Lỗi]')) 'Rename overwrote file'
    Assert ((OutputOf { doiten $renamed 'Thư mục' }).Contains('[Lỗi]')) 'Rename moved into existing directory'
    Assert ((OutputOf { doiten $renamed '..\escape.txt' }).Contains('[Lỗi]')) 'Rename accepted a path'
    Assert ([IO.File]::Exists($renamed)) 'Rejected rename changed source'
    [IO.File]::WriteAllText((Join-Path $testRoot 'Thư mục\child.txt'), 'abc')
    $tree = OutputOf { cay . 1 }
    Assert ($tree.Contains('Thư mục') -and -not $tree.Contains('child.txt')) 'Tree depth one wrong'
    Assert ((OutputOf { cay . 2 }).Contains('child.txt')) 'Tree depth two wrong'
    Assert ((OutputOf { cay . 6 }).Contains('[Lỗi]')) 'Tree accepted excess depth'
    Assert ((OutputOf { dungluong 'Thư mục' }).Contains('3 B — 1 file')) 'Folder size wrong'
    Assert ((OutputOf { dungluong 'Thư mục\child.txt' }).Contains('3 B')) 'File size wrong'
    Assert ((OutputOf { ngay }) -match '\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}') 'Date format wrong'
    $groups = @(& $module { Get-VwtMenu })
    Assert ($groups.Count -eq 7) 'Expected seven groups'
    foreach ($group in $groups) {
        $byId = OutputOf { vwt $group.Id }
        $byKey = OutputOf { vwt $group.Key }
        Assert ($byId -eq $byKey) "Group shortcut differs: $($group.Key)"
        Assert ($byId.Contains($group.Title)) 'Group title missing'
    }
    $filesMenu = OutputOf { vwt file }
    Assert ($filesMenu.Contains('doiten') -and -not $filesMenu.Contains('pingthu')) 'Group filter leaked other commands'
    $allRows = @($groups | ForEach-Object { $_.Rows })
    $catalog = @($allRows | ForEach-Object { ($_[0] -split ' ')[0] } | Select-Object -Unique)
    foreach ($command in $module.ExportedFunctions.Keys) {
        Assert ($command -in $catalog) "Export missing from menu: $command"
    }
    foreach ($command in $catalog) {
        Assert ($module.ExportedFunctions.ContainsKey($command)) "Menu command missing implementation: $command"
    }
    Assert ((OutputOf { vwt doiten }).Contains('doiten <tên> <tên mới>')) 'Individual new help failed'
    # Resolve shortcuts without changing to or modifying personal directories.
    & $module { function script:vao { param($DuongDan) $script:lastDestination = $DuongDan } }
    nha
    Assert ((& $module { $script:lastDestination }) -eq $HOME) 'Home shortcut wrong'
    foreach ($pair in @(@('ban','DesktopDirectory'), @('tailieu','MyDocuments'))) {
        $expected = [Environment]::GetFolderPath($pair[1])
        if ($expected) {
            & $pair[0]
            Assert ((& $module { $script:lastDestination }) -eq $expected) 'Known-folder shortcut wrong'
        }
    }
    Write-Host "[PASS] $script:checks command/menu assertions." -ForegroundColor Green
} finally {
    Set-Location -LiteralPath $original.Path
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $allowed = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\vwt_commands_'
    if (-not $resolved.StartsWith($allowed, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe cleanup target' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
    Remove-Module vwt
}
