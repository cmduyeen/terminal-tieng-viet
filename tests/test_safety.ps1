$ErrorActionPreference = 'Stop'
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'vwt.psm1') -Force -DisableNameChecking
$module = Get-Module vwt
$original = Get-Location
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('vwt_safe_' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($testRoot) | Out-Null
$script:checks = 0
function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    $script:checks++
}
function Test-Literal([string]$Path) { Test-Path -LiteralPath ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)) }
function OutputOf([scriptblock]$Action) { (& $Action 6>&1) | Out-String }
function AssertFailure([scriptblock]$Action) {
    $output = OutputOf $Action
    Assert ($output.Contains('[Lỗi]') -and -not $output.Contains('[OK]')) "Expected failure without success: $output"
}
function MakeZip([string]$Name, [string[]]$Entries) {
    $zip = [IO.Compression.ZipFile]::Open((Join-Path $testRoot $Name), 'Create')
    try {
        foreach ($entryName in $Entries) {
            $entry = $zip.CreateEntry($entryName)
            $writer = New-Object IO.StreamWriter($entry.Open())
            try { $writer.Write('payload') } finally { $writer.Dispose() }
        }
    } finally { $zip.Dispose() }
}
try {
    Set-Location -LiteralPath $testRoot
    & $module { param($root) $script:VwtConfigDir = Join-Path $root 'config'; $script:VwtConfigPath = Join-Path $script:VwtConfigDir 'config.json' } $testRoot
    taothumuc 'Tài liệu [2026]'
    vao 'Tài liệu [2026]'
    Assert ((Get-Location).Path -eq (Join-Path $testRoot 'Tài liệu [2026]')) 'Literal directory navigation failed'
    taofile 'Hóa đơn [1].txt'
    [IO.File]::WriteAllText((Join-Path (Get-Location).Path 'Hóa đơn [1].txt'), "Đường đến trường`nHóa đơn", [Text.Encoding]::UTF8)
    Assert ((OutputOf { xemfile 'Hóa đơn [1].txt' }).Contains('Đường đến trường')) "Vietnamese content failed: $(OutputOf { xemfile 'Hóa đơn [1].txt' })"
    Assert ((OutputOf { tim 'hoa don' }).Contains('Hóa đơn [1].txt')) 'Accent-insensitive filename search failed'
    Assert ((OutputOf { timchu 'duong den truong' }).Contains('Hóa đơn [1].txt')) 'Accent-insensitive content search failed'
    $decomposed = 'Hóa đơn'.Normalize([Text.NormalizationForm]::FormD)
    Assert ((& $module { param($text) ConvertTo-VwtSearch $text } $decomposed) -eq 'hoa don') 'Decomposed Unicode failed'
    chep 'Hóa đơn [1].txt' 'Bản sao [2].txt'
    Assert (Test-Literal 'Bản sao [2].txt') 'Literal copy failed'
    chuyen 'Bản sao [2].txt' 'Đổi tên [3].txt'
    Assert (Test-Literal 'Đổi tên [3].txt') 'Literal move failed'
    AssertFailure { chep 'Hóa đơn [1].txt' 'Đổi tên [3].txt' }
    AssertFailure { chuyen 'Hóa đơn [1].txt' 'Đổi tên [3].txt' }
    Assert (Test-Literal 'Hóa đơn [1].txt') 'Move collision lost source'
    AssertFailure { chep 'Hóa đơn [1].txt' 'missing\copy.txt' }
    AssertFailure { vao 'missing' }
    lui
    AssertFailure { chep 'Tài liệu [2026]' 'Tài liệu [2026]\child' }
    nen 'Tài liệu [2026]' 'tài liệu.zip'
    Assert (Test-Literal 'tài liệu.zip') 'Unicode ZIP failed'
    $hash = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $testRoot 'tài liệu.zip')))
    AssertFailure { nen 'Tài liệu [2026]' 'tài liệu.zip' }
    Assert ([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $testRoot 'tài liệu.zip'))) -eq $hash) 'ZIP overwritten'
    giainen 'tài liệu.zip' 'Đã giải nén [1]'
    Assert (Test-Literal 'Đã giải nén [1]\Tài liệu [2026]\Hóa đơn [1].txt') 'Unicode ZIP extraction failed'
    AssertFailure { giainen 'tài liệu.zip' 'Đã giải nén [1]' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $cases = @(
        @('parent.zip', @('valid.txt','../escaped.txt')),
        @('backslash.zip', @('..\escaped.txt')),
        @('absolute.zip', @('C:\escaped.txt')),
        @('ads.zip', @('safe.txt:stream')),
        @('duplicate.zip', @('a.txt','A.txt')),
        @('conflict.zip', @('folder','folder/file.txt')),
        @('device.zip', @('NUL.txt'))
    )
    foreach ($case in $cases) {
        MakeZip $case[0] $case[1]
        $destination = $case[0] + '-out'
        AssertFailure { giainen $case[0] $destination }
        Assert (-not (Test-Literal $destination)) 'Unsafe archive wrote destination before validation'
    }
    Assert (-not (Test-Literal 'escaped.txt')) 'ZIP escaped destination'
    # No real deletion: stub only the OS boundary and the interactive prompt.
    & $module {
        $script:answer = ''; $script:recycled = $null
        function script:Read-Host { param($Prompt) $script:answer }
        function script:Send-VwtRecycle { param($Path, $Directory) $script:recycled = $Path }
    }
    taofile 'keep.txt'
    xoa 'keep.txt'
    Assert ($null -eq (& $module { $script:recycled })) 'Enter must cancel'
    & $module { $script:answer = ' CÓ ' }
    xoa 'keep.txt'
    Assert ((& $module { $script:recycled }) -eq (Join-Path $testRoot 'keep.txt')) 'Accented confirmation or resolved target failed'
    & $module { $script:recycled = $null }
    AssertFailure { xoa '.' }
    AssertFailure { xoa ([IO.Path]::GetPathRoot($testRoot)) }
    AssertFailure { xoa '*.txt' }
    AssertFailure { xoa (Join-Path $env:windir 'System32') }
    Assert ($null -eq (& $module { $script:recycled })) 'Protected deletion reached OS'
    AssertFailure { tatapp '*' }
    vwt hoc
    Assert ((& $module { Get-VwtConfig }).bridge_mode -eq $true) 'vwt hoc failed'
    vwt gon
    Assert ((& $module { Get-VwtConfig }).bridge_mode -eq $false) 'vwt gon failed'
    AssertFailure { vwt caidat bridge typo }
    Assert ((& $module { Get-VwtConfig }).bridge_mode -eq $false) 'Invalid setting changed config'
    [IO.File]::WriteAllText((Join-Path $testRoot 'config\config.json'), '{"bridge_mode":"false"}')
    Assert ((& $module { Get-VwtConfig }).bridge_mode -eq $false) 'Malformed config not rejected'
    Assert ((OutputOf { vwt chep }).Contains('chep <nguồn> <đích>')) 'Short help failed'
    AssertFailure { vwt typo }
    [IO.Directory]::CreateDirectory((Join-Path $testRoot 'node_modules')) | Out-Null
    [IO.File]::WriteAllText((Join-Path $testRoot 'node_modules\ignored-token.txt'), 'ignored-token')
    Assert (-not (OutputOf { tim 'ignored-token' }).Contains('ignored-token.txt')) 'Ignored directory was searched'
    Assert (-not (OutputOf { timchu 'ignored-token' }).Contains('ignored-token.txt')) 'Ignored contents were searched'
    for ($i = 0; $i -lt 35; $i++) { [IO.File]::WriteAllText((Join-Path $testRoot ("limited-token-$i.txt")), 'limited-content-token') }
    $limitedNames = OutputOf { tim 'limited-token' }
    Assert (([regex]::Matches($limitedNames, 'limited-token-\d+\.txt')).Count -eq 30) 'Name result limit failed'
    Assert ($limitedNames.Contains('Còn kết quả')) 'Name truncation notice missing'
    $limitedContents = OutputOf { timchu 'limited-content-token' }
    Assert (([regex]::Matches($limitedContents, 'limited-token-\d+\.txt')).Count -eq 30) 'Content result limit failed'
    Assert ($limitedContents.Contains('Còn kết quả')) 'Content truncation notice missing'
    Write-Host "[PASS] $script:checks safety and Vietnamese assertions ($($PSVersionTable.PSVersion))." -ForegroundColor Green
} finally {
    Set-Location -LiteralPath $original.Path
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $allowed = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\vwt_safe_'
    if (-not $resolved.StartsWith($allowed, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe cleanup target' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
    Remove-Module vwt
}
