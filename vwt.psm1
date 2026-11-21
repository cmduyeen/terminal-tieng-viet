# vwt - Viet Windows Terminal cho nguoi mới hoc & tre em
# Module PowerShell chay truc tiep trong shell hien tai (vao, lui, don, lietke, nen/giainen, timchu...)

$script:VwtConfigDir = Join-Path $HOME ".vwt"
$script:VwtConfigPath = Join-Path $script:VwtConfigDir "config.json"

function Get-VwtConfig {
    if (-not (Test-Path -LiteralPath $script:VwtConfigPath)) {
        return [PSCustomObject]@{ bridge_mode = $false }
    }
    try {
        $cfg = Get-Content $script:VwtConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cfg.bridge_mode -isnot [bool]) { return [PSCustomObject]@{ bridge_mode = $false } }
        return $cfg
    } catch {
        return [PSCustomObject]@{ bridge_mode = $false }
    }
}

function Save-VwtConfig($cfg) {
    if (-not (Test-Path -LiteralPath $script:VwtConfigDir)) {
        New-Item -ItemType Directory -Path $script:VwtConfigDir -Force | Out-Null
    }
    $cfg | ConvertTo-Json | Set-Content -Path $script:VwtConfigPath -Encoding UTF8
}

function Show-VwtBridge([string]$OriginalCmd) {
    $cfg = Get-VwtConfig
    if ($cfg.bridge_mode -and $OriginalCmd) {
        Write-Host "  -> Lệnh PowerShell gốc: $OriginalCmd" -ForegroundColor DarkGray
    }
}

function Confirm-VwtAction([string]$Prompt) {
    $answer = Read-Host "? $Prompt [c/K]"
    return ((ConvertTo-VwtSearch $answer.Trim()) -match '^(c|co|y|yes|ok|1)$')
}

function Format-VwtSize([long]$Bytes) {
    if ($Bytes -ge 1GB) { return "{0:N1} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}


function ConvertTo-VwtSearch([string]$Text) {
    $value = $Text.Normalize([Text.NormalizationForm]::FormD).ToLowerInvariant().Replace('đ', 'd')
    return [regex]::Replace($value, '\p{M}', '')
}

function Get-VwtPath([string]$Path) {
    $provider = $null
    $drive = $null
    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path, [ref]$provider, [ref]$drive)
    if ($provider.Name -ne 'FileSystem') { throw 'Chỉ hỗ trợ file và thư mục trên ổ đĩa.' }
    return [IO.Path]::GetFullPath($full)
}

function Assert-VwtNoLink([string]$Path) {
    $cursor = Get-VwtPath $Path
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force -ErrorAction Stop
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Không thao tác qua liên kết thư mục: $cursor"
            }
        }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
}

function Get-VwtDestination([string]$Source, [string]$Destination) {
    $target = Get-VwtPath $Destination
    if (Test-Path -LiteralPath $target -PathType Container) {
        $target = Join-Path $target (Split-Path -Leaf $Source)
    }
    if (Test-Path -LiteralPath $target) { throw "Đích đã tồn tại: $target. Hãy chọn tên khác." }
    Assert-VwtNoLink $target
    $sourceItem = Get-Item -LiteralPath $Source -Force -ErrorAction Stop
    if ($sourceItem.PSIsContainer -and $target.StartsWith($sourceItem.FullName.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Không thể đưa thư mục vào chính nó.'
    }
    return $target
}

function Get-VwtSearchItems([string]$Directory = '.') {
    # Walk explicitly so ignored directories and junctions are never traversed.
    $pending = New-Object 'System.Collections.Generic.Stack[string]'
    $pending.Push((Get-VwtPath $Directory))
    while ($pending.Count) {
        $current = $pending.Pop()
        try { $items = @(Get-ChildItem -LiteralPath $current -ErrorAction Stop) }
        catch { Write-Warning "Không đọc được thư mục: $current"; continue }
        foreach ($item in $items) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
            if ($item.PSIsContainer -and $item.Name -in @('.git', 'node_modules', '.venv')) { continue }
            $item
            if ($item.PSIsContainer) { $pending.Push($item.FullName) }
        }
    }
}

function Send-VwtRecycle([string]$Path, [bool]$Directory) {
    if (-not [Environment]::UserInteractive) { throw 'Chỉ dùng xoa trong phiên Windows tương tác.' }
    Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction Stop
    if ($Directory) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Path, 'AllDialogs', 'SendToRecycleBin', 'ThrowException')
    } else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($Path, 'AllDialogs', 'SendToRecycleBin', 'ThrowException')
    }
}

# --- 1. Dieu huong & Thư mục ---

function vao {
    <# Di chuyen vao thư mục (cd) #>
    param([Parameter(Position=0)][string]$DuongDan)
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $DuongDan) { $DuongDan = $HOME }
        $DuongDan = Get-VwtPath $DuongDan
        if (-not (Test-Path -LiteralPath $DuongDan -PathType Container)) {
            Write-Host "[Lỗi] Không tìm thấy thư mục '$DuongDan'." -ForegroundColor Red
            Write-Host "[vwt] Gợi ý: Gõ 'lietke' để xem các thư mục đang có." -ForegroundColor Cyan
            return
        }
        Set-Location -LiteralPath $DuongDan -ErrorAction Stop
        Write-Host "[OK] Đang ở: $(Get-Location)" -ForegroundColor Green
        Show-VwtBridge "cd `"$DuongDan`""
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function lui {
    $ErrorActionPreference = 'Stop'
    try {
        <# Quay lai thư mục cha (cd ..) #>
        Set-Location -LiteralPath (Get-VwtPath '..') -ErrorAction Stop
        Write-Host "[OK] Đã lùi về: $(Get-Location)" -ForegroundColor Green
        Show-VwtBridge "cd .."
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function dangodau {
    <# Xem duong dan thư mục hien tai (pwd) #>
    Write-Host "Bạn đang ở: $(Get-Location)" -ForegroundColor Cyan
    Show-VwtBridge "pwd  (hoặc Get-Location)"
}

function lietke {
    <# Liet ke file va thư mục (ls / dir) #>
    param([Parameter(Position=0)][string]$DuongDan = ".")
    $ErrorActionPreference = 'Stop'
    try {
        $DuongDan = Get-VwtPath $DuongDan
        if (-not (Test-Path -LiteralPath $DuongDan)) {
            Write-Host "[Lỗi] Không tìm thấy '$DuongDan'." -ForegroundColor Red
            return
        }
        $items = Get-ChildItem -LiteralPath $DuongDan -ErrorAction Stop
        if ($items.Count -eq 0) {
            Write-Host "[vwt] Thư mục này đang trống." -ForegroundColor Cyan
            Show-VwtBridge "dir  (hoặc ls)"
            return
        }
        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                Write-Host ("  [Thư mục]  {0}" -f $item.Name) -ForegroundColor Yellow
            } else {
                $sz = Format-VwtSize $item.Length
                Write-Host ("  [File]     {0,-32} ({1})" -f $item.Name, $sz) -ForegroundColor White
            }
        }
        Show-VwtBridge "dir  (hoặc ls)"
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function taothumuc {
    <# Tao thư mục mới (mkdir) #>
    param([Parameter(Position=0)][string]$Ten)
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $Ten) { $Ten = Read-Host "? Nhập tên thư mục mới" }
        if (-not $Ten) { return }
        $Ten = Get-VwtPath $Ten
        if (Test-Path -LiteralPath $Ten) {
            Write-Host "[!] '$Ten' đã tồn tại." -ForegroundColor Yellow
            return
        }
        New-Item -ItemType Directory -Path $Ten | Out-Null
        Write-Host "[OK] Đã tạo thư mục '$Ten'." -ForegroundColor Green
        Show-VwtBridge "mkdir `"$Ten`""
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function taofile {
    <# Tao file rong mới #>
    param([Parameter(Position=0)][string]$Ten)
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $Ten) { $Ten = Read-Host "? Nhập tên file mới (vd: ghi-chu.txt)" }
        if (-not $Ten) { return }
        $Ten = Get-VwtPath $Ten
        if (Test-Path -LiteralPath $Ten) {
            Write-Host "[!] File '$Ten' đã tồn tại." -ForegroundColor Yellow
            return
        }
        New-Item -ItemType File -Path $Ten | Out-Null
        Write-Host "[OK] Đã tạo file '$Ten'." -ForegroundColor Green
        Show-VwtBridge "New-Item -ItemType File `"$Ten`""
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

# --- 2. Thao tac File, Tim kiem & Nen ---

function xemfile {
    <# Doc noi dung file van ban (type / cat) #>
    param([Parameter(Position=0)][string]$Ten)
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $Ten) { $Ten = Read-Host "? Nhập tên file muốn xem" }
        if ($Ten) { $Ten = Get-VwtPath $Ten }
        if (-not $Ten -or -not (Test-Path -LiteralPath $Ten -PathType Leaf)) {
            Write-Host "[Lỗi] Không tìm thấy file '$Ten'." -ForegroundColor Red
            return
        }
        Get-Content -LiteralPath $Ten -ErrorAction Stop -Encoding UTF8
        Show-VwtBridge "type `"$Ten`"  (hoặc cat `"$Ten`")"
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function chep {
    param([Parameter(Position=0)][string]$Nguon, [Parameter(Position=1)][string]$Dich)
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $Nguon) { $Nguon = Read-Host 'Nguồn' }
        if (-not $Dich) { $Dich = Read-Host 'Đích' }
        if (-not $Nguon -or -not $Dich) { return }
        $source = Get-VwtPath $Nguon
        Assert-VwtNoLink $source
        $target = Get-VwtDestination $source $Dich
        Copy-Item -LiteralPath $source -Destination $target -Recurse -ErrorAction Stop
        Write-Host "[OK] Đã chép '$Nguon' -> '$target'." -ForegroundColor Green
        Show-VwtBridge "Copy-Item -LiteralPath '$($source.Replace("'", "''"))' -Destination '$($target.Replace("'", "''"))' -Recurse"
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function chuyen {
    param([Parameter(Position=0)][string]$Nguon, [Parameter(Position=1)][string]$Dich)
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $Nguon) { $Nguon = Read-Host 'Nguồn' }
        if (-not $Dich) { $Dich = Read-Host 'Đích' }
        if (-not $Nguon -or -not $Dich) { return }
        $source = Get-VwtPath $Nguon
        Assert-VwtNoLink $source
        $target = Get-VwtDestination $source $Dich
        Move-Item -LiteralPath $source -Destination $target -ErrorAction Stop
        Write-Host "[OK] Đã chuyển '$Nguon' -> '$target'." -ForegroundColor Green
        Show-VwtBridge "Move-Item -LiteralPath '$($source.Replace("'", "''"))' -Destination '$($target.Replace("'", "''"))'"
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function xoa {
    param([Parameter(Position=0)][string]$MucTieu)
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $MucTieu) { $MucTieu = Read-Host 'File hoặc thư mục muốn bỏ vào Thùng rác' }
        if (-not $MucTieu) { return }
        $full = Get-VwtPath $MucTieu
        Assert-VwtNoLink $full
        $item = Get-Item -LiteralPath $full -Force -ErrorAction Stop
        $root = [IO.Path]::GetPathRoot($full)
        if ($full.TrimEnd('\') -eq $root.TrimEnd('\')) { throw 'Không được xóa cả ổ đĩa.' }
        foreach ($systemDirectory in @($env:windir, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
            if ($systemDirectory -and $full.StartsWith((Get-VwtPath $systemDirectory).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
                throw 'Không xóa nội dung trong thư mục hệ thống.'
            }
        }
        foreach ($protected in @($HOME, $env:windir, $env:ProgramFiles, ${env:ProgramFiles(x86)}, (Get-Location).Path)) {
            if (-not $protected) { continue }
            $protected = (Get-VwtPath $protected).TrimEnd('\')
            if ($protected -eq $full.TrimEnd('\') -or $protected.StartsWith($full.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
                throw 'Không xóa thư mục đang dùng, thư mục hệ thống hoặc thư mục cha của chúng.'
            }
        }
        $disk = New-Object IO.DriveInfo($root)
        if ($disk.DriveType -ne [IO.DriveType]::Fixed) { throw 'Chỉ hỗ trợ Thùng rác trên ổ đĩa cục bộ cố định.' }
        if (-not (Confirm-VwtAction "Bỏ '$full' vào Thùng rác?")) {
            Write-Host '[vwt] Đã hủy.' -ForegroundColor Cyan
            return
        }
        Send-VwtRecycle $full $item.PSIsContainer
        Write-Host '[OK] Đã gửi yêu cầu xóa tới Windows. Có thể khôi phục trong Thùng rác nếu Windows đã chuyển vào đó.' -ForegroundColor Green
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function tim {
    param([Parameter(Position=0)][string]$TuKhoa)
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $TuKhoa) { $TuKhoa = Read-Host 'Tên cần tìm (có dấu hoặc không dấu)' }
        if (-not $TuKhoa) { return }
        $needle = ConvertTo-VwtSearch $TuKhoa
        $found = @(Get-VwtSearchItems | Where-Object { (ConvertTo-VwtSearch $_.Name).Contains($needle) } | Select-Object -First 31)
        if (-not $found.Count) { Write-Host '[vwt] Không tìm thấy.' -ForegroundColor Cyan }
        $found | Select-Object -First 30 | ForEach-Object { Write-Host $_.FullName }
        if ($found.Count -gt 30) { Write-Host '[vwt] Còn kết quả khác. Hãy vào thư mục nhỏ hơn hoặc tìm cụ thể hơn.' }
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function timchu {
    param([Parameter(Position=0)][string]$TuKhoa, [Parameter(Position=1)][string]$MauFile = '*')
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $TuKhoa) { $TuKhoa = Read-Host 'Chữ cần tìm (có dấu hoặc không dấu)' }
        if (-not $TuKhoa) { return }
        $needle = ConvertTo-VwtSearch $TuKhoa
        $count = 0
        # Stream lines; skip binary formats and files larger than 10 MB by default.
        $textTypes = @('.txt','.md','.csv','.tsv','.json','.xml','.html','.css','.js','.ts','.py','.ps1','.psm1','.log','.ini','.yaml','.yml','.toml','.sql','')
        Get-VwtSearchItems | Where-Object { -not $_.PSIsContainer -and $_.Name -like $MauFile -and $_.Extension.ToLowerInvariant() -in $textTypes -and $_.Length -le 10MB } | ForEach-Object {
            $file = $_
            $reader = $null
            try {
                $reader = New-Object IO.StreamReader($file.FullName, [Text.Encoding]::UTF8, $true)
                $lineNumber = 0
                while ($null -ne ($line = $reader.ReadLine())) {
                    $lineNumber++
                    if ((ConvertTo-VwtSearch $line).Contains($needle)) {
                        [pscustomobject]@{ Path = $file.FullName; LineNumber = $lineNumber; Line = $line }
                    }
                }
            } catch { Write-Warning "Không đọc được file: $($file.FullName)" }
            finally { if ($reader) { $reader.Dispose() } }
        } | Select-Object -First 31 | ForEach-Object {
            $count++
            if ($count -le 30) { Write-Host ('{0} (dòng {1}): {2}' -f $_.Path, $_.LineNumber, $_.Line.Trim()) }
        }
        if (-not $count) { Write-Host '[vwt] Không tìm thấy trong các file văn bản được hỗ trợ (tối đa 10 MB/file).' }
        if ($count -gt 30) { Write-Host '[vwt] Còn kết quả khác. Hãy tìm cụ thể hơn.' }
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function nen {
    <# Nen file hoac thư mục thanh file .zip #>
    param(
        [Parameter(Position=0)][string]$Nguon,
        [Parameter(Position=1)][string]$FileZip
    )
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $Nguon) { $Nguon = Read-Host "? Nhập tên file hoặc thư mục muốn nén" }
        if ($Nguon) { $Nguon = Get-VwtPath $Nguon }
        if (-not $Nguon -or -not (Test-Path -LiteralPath $Nguon)) {
            Write-Host "[Lỗi] Không tìm thấy '$Nguon'." -ForegroundColor Red
            return
        }
        if (-not $FileZip) {
            $base = (Get-Item -LiteralPath $Nguon -ErrorAction Stop).BaseName
            $FileZip = "$base.zip"
        }
        if (-not $FileZip.EndsWith('.zip', [StringComparison]::OrdinalIgnoreCase)) { $FileZip += '.zip' }
        $FileZip = Get-VwtPath $FileZip
        if (Test-Path -LiteralPath $FileZip) { throw "File ZIP đã tồn tại: $FileZip. Hãy chọn tên khác." }
        Compress-Archive -LiteralPath $Nguon -DestinationPath $FileZip -ErrorAction Stop
        Write-Host "[OK] Đã nén '$Nguon' -> '$FileZip'." -ForegroundColor Green
        Show-VwtBridge "Compress-Archive -Path `"$Nguon`" -DestinationPath `"$FileZip`""
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function giainen {
    param([Parameter(Position=0)][string]$FileZip, [Parameter(Position=1)][string]$Dich)
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $FileZip) { $FileZip = Read-Host 'File ZIP' }
        if (-not $FileZip) { return }
        $source = Get-Item -LiteralPath (Get-VwtPath $FileZip) -ErrorAction Stop
        if (-not $Dich) { $Dich = $source.BaseName }
        $destination = Get-VwtPath $Dich
        Assert-VwtNoLink $destination
        if (Test-Path -LiteralPath $destination) { throw "Đích đã tồn tại: $destination. Hãy chọn thư mục mới." }
        $prefix = $destination.TrimEnd('\') + '\'
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($source.FullName)
    try {
            $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
            $files = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
            $plan = New-Object 'System.Collections.Generic.List[object]'
            [long]$totalBytes = 0
            if ($zip.Entries.Count -gt 10000) { throw 'ZIP vượt giới hạn 10.000 mục. Hãy dùng ứng dụng giải nén chuyên dụng.' }
            foreach ($entry in $zip.Entries) {
                $name = $entry.FullName.Replace('/', '\')
                if ([IO.Path]::IsPathRooted($name)) { throw 'ZIP có đường dẫn tuyệt đối không an toàn.' }
                foreach ($part in $name.TrimEnd('\').Split('\')) {
                    if (-not $part -or $part -in @('.', '..') -or $part -match '[<>:"|?*\x00-\x1f]' -or $part -match '[. ]$' -or $part -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)') {
                        throw "Tên mục ZIP không an toàn: $($entry.FullName)"
                    }
                }
                $target = [IO.Path]::GetFullPath([IO.Path]::Combine($destination, $name))
                if (-not $target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'ZIP chứa đường dẫn vượt khỏi thư mục đích.' }
                if (-not $seen.Add($target.TrimEnd('\'))) { throw 'ZIP có các mục trùng tên.' }
                $isDirectory = $name.EndsWith('\')
                if (-not $isDirectory) { [void]$files.Add($target) }
                $totalBytes += $entry.Length
                if ($totalBytes -gt 2GB) { throw 'ZIP vượt giới hạn 2 GB sau giải nén. Hãy dùng ứng dụng giải nén chuyên dụng.' }
                $plan.Add([pscustomobject]@{ Entry = $entry; Target = $target; Directory = $isDirectory })
            }
            # Validate the entire archive before writing anything.
            foreach ($record in $plan) {
                $parent = [IO.Path]::GetDirectoryName($record.Target.TrimEnd('\'))
                while ($parent -and $parent.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                    if ($files.Contains($parent)) { throw 'ZIP có file trùng đường dẫn thư mục.' }
                    $parent = [IO.Path]::GetDirectoryName($parent)
                }
            }
            [IO.Directory]::CreateDirectory($destination) | Out-Null
            foreach ($record in $plan) {
                if ($record.Directory) { [IO.Directory]::CreateDirectory($record.Target) | Out-Null }
                else {
                    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($record.Target)) | Out-Null
                    [IO.Compression.ZipFileExtensions]::ExtractToFile($record.Entry, $record.Target, $false)
                }
            }
        } finally { $zip.Dispose() }
        Write-Host "[OK] Đã giải nén vào '$destination'." -ForegroundColor Green
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

# --- 3. He thong, Mang & Tien ich ---

function don {
    <# Xoa sach man hinh terminal (cls / clear) #>
    Clear-Host
    Show-VwtBridge "cls  (hoặc clear)"
}

function mo {
    <# Mo thư mục hoac file bang Windows Explorer / ung dung mac dinh #>
    param([Parameter(Position=0)][string]$MucTieu = ".")
    $ErrorActionPreference = 'Stop'
    try {
        $MucTieu = Get-VwtPath $MucTieu
        if (-not (Test-Path -LiteralPath $MucTieu)) {
            Write-Host "[Lỗi] Không tìm thấy '$MucTieu'." -ForegroundColor Red
            return
        }
        Invoke-Item -LiteralPath $MucTieu -ErrorAction Stop
        Write-Host "[OK] Đã mở '$MucTieu'." -ForegroundColor Green
        Show-VwtBridge "start `"$MucTieu`"  (hoặc explorer .)"
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

function mang {
    <# Xem thong tin mang va dia chi IP (ipconfig) #>
    $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.InterfaceAlias -notlike "*Loopback*" }
    if ($ips) {
        Write-Host "Địa chỉ IP máy bạn:" -ForegroundColor Cyan
        foreach ($ip in $ips) {
            Write-Host ("  [{0}] {1}" -f $ip.InterfaceAlias, $ip.IPAddress)
        }
    } else {
        ipconfig
    }
    Show-VwtBridge "ipconfig"
}

function pingthu {
    <# Kiem tra ket noi mang toi mot trang web (ping) #>
    param([Parameter(Position=0)][string]$DiaChi = "google.com")
    Write-Host "[vwt] Đang thử kết nối tới $DiaChi..." -ForegroundColor Cyan
    ping -n 4 $DiaChi
    Show-VwtBridge "ping $DiaChi"
}

function cong {
    <# Kiem tra xem cong mang (port) nao dang bi chiem boi app nao #>
    param([Parameter(Position=0)][int]$SoCong = 0)
    if ($SoCong -lt 0 -or $SoCong -gt 65535) { Write-Host '[Lỗi] Cổng phải từ 1 đến 65535; bỏ trống để xem tất cả.'; return }
    try { $conns = Get-NetTCPConnection -State Listen -ErrorAction Stop }
    catch { Write-Host '[Lỗi] Không đọc được thông tin cổng mạng.' -ForegroundColor Red; return }
    if ($SoCong -gt 0) {
        $conns = $conns | Where-Object { $_.LocalPort -eq $SoCong }
    }
    if (-not $conns) {
        $msg = if ($SoCong -gt 0) { "Cổng $SoCong đang trống (chưa có ứng dụng dùng)." } else { "Không có cổng nào đang mở." }
        Write-Host "[vwt] $msg" -ForegroundColor Cyan
    } else {
        Write-Host "Các cổng mạng đang được sử dụng:" -ForegroundColor Cyan
        $conns | Sort-Object LocalPort | Select-Object -First 20 | ForEach-Object {
            $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
            $pname = if ($proc) { $proc.ProcessName } else { "PID $($_.OwningProcess)" }
            Write-Host ("  Cổng {0,-6} <- {1} (PID {2})" -f $_.LocalPort, $pname, $_.OwningProcess)
        }
    }
    Show-VwtBridge "netstat -ano  (hoặc Get-NetTCPConnection -State Listen)"
}

function odia {
    <# Xem dung luong con trong cua cac o dia (C:, D:...) #>
    Write-Host "Dung lượng các ổ đĩa:" -ForegroundColor Cyan
    Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null -or $_.Free -ne $null } | ForEach-Object {
        if ($null -eq $_.Free -or $null -eq $_.Used -or ($_.Free + $_.Used) -eq 0) {
            Write-Host ("  Ổ {0}: chưa đọc được dung lượng." -f $_.Name)
            return
        }
        $free = Format-VwtSize $_.Free
        $used = Format-VwtSize $_.Used
        Write-Host ("  Ổ {0}:  Còn trống {1,-10} | Đã dùng {2}" -f $_.Name, $free, $used)
    }
    Show-VwtBridge "Get-PSDrive -PSProvider FileSystem"
}

function maytinh {
    <# Xem thong tin co ban cua may tinh (ten may, Windows, RAM) #>
    try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop }
    catch { $os = $null; Write-Host '[vwt] Chưa đọc được thông tin Windows/RAM.' -ForegroundColor Yellow }
    $ramGb = if ($os) { "{0:N1} GB" -f ($os.TotalVisibleMemorySize / 1MB) } else { "?" }
    $osName = if ($os) { $os.Caption } else { "Windows" }
    Write-Host "Thông tin máy tính:" -ForegroundColor Cyan
    Write-Host "  Tên máy    : $env:COMPUTERNAME"
    Write-Host "  Người dùng : $env:USERNAME"
    Write-Host "  Hệ điều hành: $osName"
    Write-Host "  Tổng RAM   : $ramGb"
    Show-VwtBridge "systeminfo"
}

function tientrinh {
    <# Xem cac ung dung/chuong trinh dang chay #>
    param([Parameter(Position=0)][string]$Ten = "*")
    Get-Process -Name "*$Ten*" -ErrorAction SilentlyContinue |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First 15 |
        Format-Table Name, Id, @{Name="RAM (MB)";Expression={[math]::Round($_.WorkingSet64/1MB,1)}} -AutoSize
    Show-VwtBridge "tasklist  (hoặc Get-Process)"
}

function tatapp {
    <# Tat mot ung dung dang bi treo theo ten #>
    param([Parameter(Position=0)][string]$Ten)
    $ErrorActionPreference = 'Stop'
    try {
        if (-not $Ten) { $Ten = Read-Host "? Nhập tên ứng dụng muốn tắt (vd: notepad)" }
        if (-not $Ten) { return }
        if ($Ten.IndexOfAny([char[]]'*?[]') -ge 0) { throw 'Hãy nhập đúng tên ứng dụng, không dùng ký tự đại diện.' }
        $procs = @(Get-Process -Name $Ten -ErrorAction SilentlyContinue)
        if (-not $procs) {
            Write-Host "[vwt] Không thấy ứng dụng '$Ten' đang chạy." -ForegroundColor Cyan
            return
        }
        if (-not (Confirm-VwtAction "Tắt '$Ten' ($($procs.Count) tiến trình)? Dữ liệu chưa lưu có thể mất.")) {
            Write-Host "[vwt] Đã hủy." -ForegroundColor Cyan
            return
        }
        Stop-Process -InputObject $procs -Force -ErrorAction Stop
        Write-Host "[OK] Đã tắt '$Ten'." -ForegroundColor Green
        Show-VwtBridge "taskkill /IM $Ten.exe /F"
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

. (Join-Path $PSScriptRoot 'commands.ps1')
. (Join-Path $PSScriptRoot 'menu.ps1')

function vwt {
    <# Huong dan va cai dat cho vwt (Viet Windows Terminal) #>
    param(
        [Parameter(Position=0)][string]$Lenh = "huongdan",
        [Parameter(Position=1)][string]$ThamSo1,
        [Parameter(Position=2)][string]$ThamSo2
    )
    $ErrorActionPreference = 'Stop'
    try {
        if ($Lenh -in @('gon', 'hoc')) {
            $ThamSo2 = if ($Lenh -eq 'hoc') { 'bat' } else { 'tat' }
            $Lenh = 'caidat'; $ThamSo1 = 'bridge'
        }
        if ($Lenh -eq "caidat" -and $ThamSo1 -eq "bridge") {
            if ($ThamSo2 -notin @('bat','tat','on','off','true','false','1','0','co','khong')) { throw 'Dùng: vwt gon hoặc vwt hoc.' }
            $cfg = Get-VwtConfig
            $bat = ($ThamSo2 -match '^(bat|on|true|1|co)$')
            $cfg.bridge_mode = $bat
            Save-VwtConfig $cfg
            $trangThai = if ($bat) { "bật" } else { "tắt" }
            Write-Host "[OK] Đã $trangThai gợi ý lệnh gốc." -ForegroundColor Green
            return
        }

        Show-VwtMenu $Lenh
    } catch {
        Write-Host ("[Lỗi] " + $_.Exception.Message) -ForegroundColor Red
    }
}

Export-ModuleMember -Function vao, lui, dangodau, lietke, taothumuc, taofile, xemfile, chep, chuyen, xoa, tim, timchu, nen, giainen, don, mo, mang, pingthu, cong, odia, maytinh, tientrinh, tatapp, vwt, nha, ban, tailieu, doiten, cay, dungluong, dau, cuoi, dem, ngay
