# Extra commands, loaded in module scope. Keep names short and paths literal.
function nha { vao $HOME }

function ban {
    $path = [Environment]::GetFolderPath('DesktopDirectory')
    if (-not $path) { Write-Host '[Lỗi] Chưa tìm thấy thư mục Desktop.' -ForegroundColor Red; return }
    vao $path
}

function tailieu {
    $path = [Environment]::GetFolderPath('MyDocuments')
    if (-not $path) { Write-Host '[Lỗi] Chưa tìm thấy thư mục Documents.' -ForegroundColor Red; return }
    vao $path
}

function doiten {
    param([Parameter(Position=0)][string]$Ten, [Parameter(Position=1)][string]$TenMoi)
    try {
        if (-not $Ten) { $Ten = Read-Host 'Tên hiện tại' }
        if (-not $TenMoi) { $TenMoi = Read-Host 'Tên mới' }
        if (-not $Ten -or -not $TenMoi) { return }
        if ($TenMoi -in @('.', '..') -or $TenMoi.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or $TenMoi -match '[. ]$') {
            throw 'Chỉ nhập tên mới, không nhập đường dẫn. Muốn chuyển thư mục, dùng chuyen.'
        }
        $source = Get-VwtPath $Ten
        $target = Join-Path ([IO.Path]::GetDirectoryName($source)) $TenMoi
        # Refuse any existing target, including directories; do not move into it.
        if (Test-Path -LiteralPath $target) { throw 'Tên mới đã tồn tại. Hãy chọn tên khác.' }
        chuyen $source $target
    } catch { Write-Host ('[Lỗi] ' + $_.Exception.Message) -ForegroundColor Red }
}

function cay {
    param([Parameter(Position=0)][string]$DuongDan = '.', [Parameter(Position=1)][int]$Sau = 2)
    try {
        if ($Sau -lt 1 -or $Sau -gt 5) { throw 'Độ sâu từ 1 đến 5. Ví dụ: cay . 3' }
        $root = Get-VwtPath $DuongDan
        $item = Get-Item -LiteralPath $root -Force -ErrorAction Stop
        if (-not $item.PSIsContainer) { throw 'Hãy chọn một thư mục.' }
        Assert-VwtNoLink $root
        Write-Host $root -ForegroundColor Cyan
        $pending = New-Object 'System.Collections.Generic.Stack[object]'
        $pending.Push([pscustomobject]@{ Path = $root; Depth = 0 })
        $count = 0
        while ($pending.Count) {
            $node = $pending.Pop()
            if ($node.Depth -gt 0) {
                $count++
                if ($count -gt 100) { Write-Host '[vwt] Chỉ hiện 100 mục. Hãy chọn thư mục nhỏ hơn.'; break }
                $name = [IO.Path]::GetFileName($node.Path)
                Write-Host (('  ' * ($node.Depth - 1)) + '|-- ' + $name)
            }
            if ($node.Depth -ge $Sau) { continue }
            $current = Get-Item -LiteralPath $node.Path -Force -ErrorAction Stop
            if (-not $current.PSIsContainer -or ($current.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
            try {
                $children = @(Get-ChildItem -LiteralPath $node.Path -ErrorAction Stop |
                    Where-Object { $_.Name -notin @('.git','node_modules','.venv') } |
                    Sort-Object -Property @{Expression='PSIsContainer'; Descending=$true}, Name)
            } catch { Write-Warning "Không đọc được: $($node.Path)"; continue }
            for ($i = $children.Count - 1; $i -ge 0; $i--) {
                $pending.Push([pscustomobject]@{ Path = $children[$i].FullName; Depth = $node.Depth + 1 })
            }
        }
    } catch { Write-Host ('[Lỗi] ' + $_.Exception.Message) -ForegroundColor Red }
}

function dungluong {
    param([Parameter(Position=0)][string]$DuongDan = '.')
    try {
        $root = Get-VwtPath $DuongDan
        $item = Get-Item -LiteralPath $root -Force -ErrorAction Stop
        Assert-VwtNoLink $root
        if (-not $item.PSIsContainer) {
            Write-Host ("{0}: {1}" -f $item.Name, (Format-VwtSize $item.Length))
            return
        }
        $pending = New-Object 'System.Collections.Generic.Stack[string]'
        $pending.Push($root)
        [long]$bytes = 0
        [long]$count = 0
        $skipped = 0
        while ($pending.Count) {
            $current = $pending.Pop()
            try { $children = @(Get-ChildItem -LiteralPath $current -Force -ErrorAction Stop) }
            catch { $skipped++; continue }
            foreach ($child in $children) {
                if ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) { $skipped++; continue }
                if ($child.PSIsContainer) { $pending.Push($child.FullName) }
                else { $count++; $bytes += $child.Length }
            }
        }
        Write-Host ("{0}: {1} — {2} file" -f $root, (Format-VwtSize $bytes), $count)
        if ($skipped) { Write-Host "[vwt] Chưa tính $skipped mục không đọc được hoặc liên kết." -ForegroundColor Yellow }
    } catch { Write-Host ('[Lỗi] ' + $_.Exception.Message) -ForegroundColor Red }
}

function Read-VwtLines([string]$Ten, [int]$SoDong, [bool]$Last) {
    if (-not $Ten) { $Ten = Read-Host 'File văn bản' }
    if (-not $Ten) { return }
    if ($SoDong -lt 1 -or $SoDong -gt 1000) { throw 'Số dòng từ 1 đến 1000.' }
    $path = Get-VwtPath $Ten
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'Không tìm thấy file văn bản.' }
    if ($Last) { Get-Content -LiteralPath $path -Encoding UTF8 -Tail $SoDong -ErrorAction Stop }
    else { Get-Content -LiteralPath $path -Encoding UTF8 -TotalCount $SoDong -ErrorAction Stop }
}

function dau {
    param([Parameter(Position=0)][string]$Ten, [Parameter(Position=1)][int]$SoDong = 10)
    try { Read-VwtLines $Ten $SoDong $false }
    catch { Write-Host ('[Lỗi] ' + $_.Exception.Message) -ForegroundColor Red }
}

function cuoi {
    param([Parameter(Position=0)][string]$Ten, [Parameter(Position=1)][int]$SoDong = 10)
    try { Read-VwtLines $Ten $SoDong $true }
    catch { Write-Host ('[Lỗi] ' + $_.Exception.Message) -ForegroundColor Red }
}

function dem {
    param([Parameter(Position=0)][string]$Ten)
    $reader = $null
    try {
        if (-not $Ten) { $Ten = Read-Host 'File văn bản' }
        if (-not $Ten) { return }
        $path = Get-VwtPath $Ten
        $reader = New-Object IO.StreamReader($path, [Text.Encoding]::UTF8, $true)
        [long]$lines = 0
        [long]$words = 0
        while ($null -ne ($line = $reader.ReadLine())) {
            $lines++
            $words += [regex]::Matches($line, '\S+').Count
        }
        Write-Host ("{0}: {1} dòng, {2} từ (tách theo khoảng trắng)" -f $Ten, $lines, $words)
    } catch { Write-Host ('[Lỗi] ' + $_.Exception.Message) -ForegroundColor Red }
    finally { if ($reader) { $reader.Dispose() } }
}

function ngay {
    Write-Host (Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
}
