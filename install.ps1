$ErrorActionPreference = "Stop"

$ModuleDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulePath = Join-Path $ModuleDir "vwt.psm1"

if (-not (Test-Path $ModulePath)) {
    Write-Host "[Loi] Khong tim thay file vwt.psm1 tai $ModulePath" -ForegroundColor Red
    exit 1
}

$ProfileTargets = @($PROFILE)
$Pwsh7Profile = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"
if ($Pwsh7Profile -ne $PROFILE) {
    $ProfileTargets += $Pwsh7Profile
}

$StartMarker = "# >>> vwt >>>"
$EndMarker = "# <<< vwt <<<"
$Block = @"
$StartMarker
Import-Module "$ModulePath" -DisableNameChecking
$EndMarker
"@

foreach ($target in $ProfileTargets) {
    $dir = Split-Path -Parent $target
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    if (-not (Test-Path $target)) {
        New-Item -ItemType File -Path $target -Force | Out-Null
    }

    $content = Get-Content $target -Raw -Encoding UTF8
    if ($null -eq $content) { $content = "" }

    $pattern = [regex]::Escape($StartMarker) + "[\s\S]*?" + [regex]::Escape($EndMarker)
    if ($content -match $pattern) {
        $updated = [regex]::Replace($content, $pattern, $Block)
    } else {
        $sep = if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) { "`r`n`r`n" } else { "`r`n" }
        $updated = $content + $sep + $Block + "`r`n"
    }

    Set-Content -Path $target -Value $updated -Encoding UTF8
    Write-Host "[OK] Da nap vwt vao PowerShell profile: $target" -ForegroundColor Green
}

Write-Host "[OK] Cai dat thanh cong! Hay mo terminal PowerShell moi va go: vwt" -ForegroundColor Cyan
