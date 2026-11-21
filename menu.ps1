# One catalog for the complete menu, group filters and individual command help.
function Get-VwtMenu {
    @(
        @{ Id='1'; Key='di'; Title='Đi lại & thư mục'; Rows=@(
            @('vao <thư mục>', 'Vào thư mục'),
            @('lui', 'Lùi về thư mục cha'),
            @('nha', 'Về thư mục cá nhân'),
            @('ban', 'Vào Desktop'),
            @('tailieu', 'Vào Documents'),
            @('dangodau', 'Xem vị trí hiện tại'),
            @('lietke [thư mục]', 'Xem danh sách file'),
            @('cay [thư mục] [sâu]', 'Xem cây thư mục; mặc định sâu 2 cấp'),
            @('taothumuc <tên>', 'Tạo thư mục'),
            @('mo [tên]', 'Mở bằng ứng dụng mặc định')
        ) },
        @{ Id='2'; Key='file'; Title='File & nội dung'; Rows=@(
            @('taofile <tên>', 'Tạo file trống'),
            @('xemfile <file>', 'Đọc văn bản UTF-8'),
            @('dau <file> [dòng]', 'Xem các dòng đầu; mặc định 10'),
            @('cuoi <file> [dòng]', 'Xem các dòng cuối; mặc định 10'),
            @('dem <file>', 'Đếm dòng và từ theo khoảng trắng'),
            @('chep <nguồn> <đích>', 'Chép; dừng nếu trùng tên'),
            @('chuyen <nguồn> <đích>', 'Chuyển; dừng nếu trùng tên'),
            @('doiten <tên> <tên mới>', 'Đổi tên ngay trong thư mục cũ'),
            @('xoa <tên>', 'Yêu cầu Windows chuyển vào Thùng rác'),
            @('dungluong [tên]', 'Tính dung lượng file/thư mục, kể cả file ẩn')
        ) },
        @{ Id='3'; Key='timkiem'; Title='Tìm kiếm'; Rows=@(
            @('tim <từ>', 'Tìm tên, có dấu hoặc không dấu'),
            @('timchu <chữ> [mẫu]', 'Tìm trong văn bản; tối đa 10 MB/file')
        ) },
        @{ Id='4'; Key='zip'; Title='Nén & giải nén'; Rows=@(
            @('nen <nguồn> [zip]', 'Nén ZIP; không ghi đè'),
            @('giainen <zip> [đích]', 'Giải nén vào thư mục mới')
        ) },
        @{ Id='5'; Key='may'; Title='Máy tính & ứng dụng'; Rows=@(
            @('odia', 'Xem dung lượng ổ đĩa'),
            @('maytinh', 'Xem thông tin máy'),
            @('tientrinh [tên]', 'Xem ứng dụng đang chạy'),
            @('tatapp <tên>', 'Buộc tắt ứng dụng; có xác nhận'),
            @('ngay', 'Xem ngày giờ theo giờ máy')
        ) },
        @{ Id='6'; Key='net'; Title='Mạng & kết nối'; Rows=@(
            @('mang', 'Xem địa chỉ IP'),
            @('pingthu <web>', 'Thử kết nối mạng'),
            @('cong [số]', 'Xem ứng dụng dùng cổng mạng')
        ) },
        @{ Id='7'; Key='giup'; Title='Hướng dẫn & hiển thị'; Rows=@(
            @('vwt [nhóm/lệnh]', 'Xem tất cả, một nhóm hoặc một lệnh'),
            @('vwt gon', 'Ẩn gợi ý lệnh gốc'),
            @('vwt hoc', 'Hiện gợi ý để học PowerShell'),
            @('don', 'Dọn màn hình')
        ) }
    )
}

function Show-VwtMenu([string]$Selection = 'huongdan') {
    $groups = @(Get-VwtMenu)
    $all = $Selection -in @('huongdan', 'tatca')
    $selected = @($groups | Where-Object { $all -or $_.Id -eq $Selection -or $_.Key -eq $Selection })
    if (-not $selected.Count) {
        $rows = @($groups | ForEach-Object { $_.Rows } | Where-Object { ($_[0] -split ' ')[0] -eq $Selection })
        if (-not $rows.Count) { throw 'Không có nhóm/lệnh này. Gõ vwt để xem menu.' }
        Write-Host ("vwt — Hướng dẫn: $Selection") -ForegroundColor Cyan
        foreach ($row in $rows) { Write-Host ('  {0,-27} {1}' -f $row[0], $row[1]) }
    } else {
        Write-Host 'vwt — Lệnh tiếng Việt theo nhóm' -ForegroundColor Cyan
        foreach ($group in $selected) {
            Write-Host ("`n{0}. {1}  (vwt {0} / vwt {2})" -f $group.Id, $group.Title, $group.Key) -ForegroundColor Yellow
            foreach ($row in $group.Rows) { Write-Host ('  {0,-27} {1}' -f $row[0], $row[1]) }
        }
    }
    Write-Host "`nXem nhóm: vwt 2 | Xem lệnh: vwt chep | Tên có khoảng trắng: đặt trong ngoặc kép." -ForegroundColor DarkGray
}
