$ErrorActionPreference = "Stop"

$ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) "vwt.psm1"
Import-Module $ModulePath -Force -DisableNameChecking

$OrigDir = Get-Location
$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("vwt_test_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TempDir | Out-Null

try {
    Set-Location $TempDir

    taothumuc "du_an"
    if (-not (Test-Path (Join-Path $TempDir "du_an"))) { throw "taothumuc failed" }

    vao "du_an"
    if ((Get-Location).Path -ne (Join-Path $TempDir "du_an")) { throw "vao failed" }

    taofile "ghi_chu.txt"
    "xin chao vwt timchu_token" | Set-Content -Path "ghi_chu.txt" -Encoding UTF8

    $findTextOut = (timchu "timchu_token" 6>&1) | Out-String
    if ($findTextOut -notmatch "ghi_chu\.txt") { throw "timchu failed" }

    chep "ghi_chu.txt" "ban_sao.txt"
    chuyen "ban_sao.txt" "da_doi_ten.txt"
    if (-not (Test-Path "da_doi_ten.txt")) { throw "chep/chuyen failed" }

    lui
    if ((Get-Location).Path -ne $TempDir) { throw "lui failed" }

    nen "du_an" "du_an.zip"
    if (-not (Test-Path "du_an.zip")) { throw "nen failed" }

    giainen "du_an.zip" "giai_nen_out"
    if (-not (Test-Path "giai_nen_out\du_an\ghi_chu.txt")) { throw "giainen failed" }

    odia | Out-Null
    maytinh | Out-Null
    vwt | Out-Null

    Write-Host "[PASS] Tat ca cac kiem thu vwt deu thanh cong!" -ForegroundColor Green
} finally {
    Set-Location $OrigDir
    $resolved = [IO.Path]::GetFullPath($TempDir)
    $allowed = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\vwt_test_'
    if (-not $resolved.StartsWith($allowed, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe cleanup target' }
    Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction Stop
}
