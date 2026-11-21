$ErrorActionPreference = "Stop"

$ProfileTargets = @($PROFILE)
$Pwsh7Profile = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1"
if ($Pwsh7Profile -ne $PROFILE) {
    $ProfileTargets += $Pwsh7Profile
}

$StartMarker = "# >>> vwt >>>"
$EndMarker = "# <<< vwt <<<"
$pattern = "(\r?\n)*" + [regex]::Escape($StartMarker) + "[\s\S]*?" + [regex]::Escape($EndMarker) + "(\r?\n)*"

foreach ($target in $ProfileTargets) {
    if (Test-Path $target) {
        $content = Get-Content $target -Raw -Encoding UTF8
        if ($content -match [regex]::Escape($StartMarker)) {
            $updated = [regex]::Replace($content, $pattern, "`r`n")
            Set-Content -Path $target -Value $updated.TrimStart() -Encoding UTF8
            Write-Host "[OK] Da go vwt khoi: $target" -ForegroundColor Green
        }
    }
}
