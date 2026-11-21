# vwt — Terminal tiếng Việt, lệnh ngắn

[Tiếng Việt](README.md) · [English](README.en.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Buy%20me%20a%20coffee-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/cmduyeen)

Module PowerShell cho Windows, hướng tới người mới. Lệnh không dấu để dễ gõ; hướng dẫn có dấu để dễ đọc.

## Dùng ngay

Trong thư mục dự án:

```powershell
Import-Module .\vwt.psm1 -Force -DisableNameChecking
vwt
```

Tự nạp khi mở PowerShell: `./install.ps1`. Gỡ tự nạp: `./uninstall.ps1`.
Installer tham chiếu trực tiếp thư mục dự án; chuyển thư mục thì chạy lại installer. Chỉ import module không sửa profile.

## Menu theo nhóm

Gõ `vwt` để xem toàn bộ menu, có tiêu đề chia nhóm. Xem riêng một nhóm bằng số hoặc tên ngắn:

| Số | Lệnh | Nhóm |
|---|---|---|
| 1 | `vwt di` | Đi lại & thư mục |
| 2 | `vwt file` | File & nội dung |
| 3 | `vwt timkiem` | Tìm kiếm |
| 4 | `vwt zip` | Nén & giải nén |
| 5 | `vwt may` | Máy tính & ứng dụng |
| 6 | `vwt net` | Mạng & kết nối |
| 7 | `vwt giup` | Hướng dẫn & hiển thị |

Ví dụ: `vwt 2` tương đương `vwt file`. `vwt doiten` chỉ hiện hướng dẫn lệnh đổi tên. Menu chỉ hiển thị hướng dẫn, không tự thực thi lệnh khi chọn nhóm.

## 10 lệnh bổ sung

| Lệnh | Công dụng |
|---|---|
| `nha` | Về thư mục cá nhân |
| `ban` | Vào Desktop theo vị trí Windows đã cấu hình |
| `tailieu` | Vào Documents theo vị trí Windows đã cấu hình |
| `doiten a.txt b.txt` | Đổi tên trong thư mục cũ, không ghi đè hoặc chuyển vào thư mục trùng tên |
| `cay` | Xem cây thư mục hiện tại, sâu 2 cấp |
| `dungluong` | Tính dung lượng thư mục hiện tại |
| `dau a.txt` | Xem 10 dòng đầu |
| `cuoi a.txt` | Xem 10 dòng cuối |
| `dem a.txt` | Đếm dòng và từ, tách từ theo khoảng trắng |
| `ngay` | Ngày giờ máy theo định dạng ngày/tháng/năm |

Có thể thêm một số ngắn: `dau a.txt 5`, `cuoi a.txt 20`, `cay . 3`.

`cay` nhận độ sâu 1–5, hiển thị tối đa 100 mục; bỏ qua file ẩn, `.git`, `node_modules`, `.venv` và không đi vào liên kết thư mục. `dungluong` tính cả file ẩn và các thư mục này, bỏ qua liên kết, báo số mục không tính được; đây là tổng kích thước nội dung file, không phải dung lượng cấp phát thực trên đĩa. Thư mục lớn có thể cần thời gian quét.

`dau` / `cuoi` đọc văn bản UTF-8, nhận 1–1000 dòng. `dem` đọc từng dòng, nhận UTF-8 hoặc encoding có BOM; không phân tích định dạng Word/PDF và không tách từ theo ngữ nghĩa tiếng Việt.

## Lệnh thường dùng

| Lệnh | Công dụng |
|---|---|
| `vao "Tài liệu"` | Vào thư mục; `vao` về thư mục cá nhân |
| `lui` | Lùi một cấp |
| `lietke` | Xem file và thư mục |
| `dangodau` | Xem vị trí hiện tại |
| `taothumuc "Bài tập"` | Tạo thư mục |
| `taofile "Ghi chú.txt"` | Tạo file trống |
| `xemfile "Ghi chú.txt"` | Đọc văn bản UTF-8 |
| `chep a.txt b.txt` | Chép file hoặc thư mục |
| `chuyen a.txt b.txt` | Chuyển hoặc đổi tên |
| `xoa a.txt` | Hỏi rồi yêu cầu Windows chuyển vào Thùng rác |
| `tim "hoa don"` | Tìm cả tên “Hóa đơn” |
| `timchu "duong den"` | Tìm cả nội dung “đường đến” |
| `nen "Bài tập"` | Tạo `Bài tập.zip` |
| `giainen bai.zip` | Giải nén vào thư mục mới `bai` |
| `mo` | Mở thư mục hiện tại |
| `don` | Dọn màn hình |
| `vwt chep` | Hướng dẫn riêng cho `chep` |
| `vwt gon` | Ẩn gợi ý lệnh gốc |
| `vwt hoc` | Hiện gợi ý để học PowerShell |

Tên có khoảng trắng cần đặt trong dấu ngoặc kép. Dùng Tab để hoàn thành đường dẫn. Các lệnh file thiếu tham số sẽ hỏi từng bước. Tên có dấu và dấu `[]` được xử lý như tên thật.

Lệnh hệ thống vẫn có: `odia`, `maytinh`, `mang`, `pingthu <web>`, `cong [số]`, `tientrinh [tên]`, `tatapp <tên>`.

## Mặc định an toàn

- Chép, chuyển, nén: dừng nếu đích đã tồn tại; chọn tên khác để tiếp tục. Không gộp thư mục đang tồn tại.
- Giải nén: chỉ nhận thư mục đích chưa tồn tại; kiểm tra toàn bộ tên mục trước khi ghi. Chặn đường dẫn thoát ra ngoài, tên trùng, tên thiết bị Windows và luồng dữ liệu phụ. Giới hạn 10.000 mục / 2 GB sau giải nén.
- Xóa: hiển thị đường dẫn đầy đủ; Enter là hủy, `c`, `co`, `có` là đồng ý. Chặn ổ đĩa gốc, thư mục cá nhân, thư mục hệ thống, thư mục đang dùng và các thư mục cha. Chỉ hỗ trợ ổ đĩa cục bộ cố định; không đi qua junction/symlink ở đường dẫn đích.
- Xóa dùng [API Thùng rác Windows](https://learn.microsoft.com/en-us/dotnet/api/microsoft.visualbasic.fileio.filesystem.deletefile), bật hộp thoại hệ thống. Nếu Windows đề nghị xóa vĩnh viễn vì không thể dùng Thùng rác, chọn **Hủy** để giữ file. Module không tự chuyển sang `Remove-Item` khi có lỗi.
- `tatapp` cần đúng tên ứng dụng, không nhận `*`; luôn hỏi vì dữ liệu chưa lưu có thể mất.
- Thao tác thất bại không báo `[OK]`. Nếu thao tác nhiều file lỗi giữa chừng, phần đã chép/giải nén có thể còn lại; chưa có giao dịch hoàn tác tự động.

## Tìm kiếm và hiển thị

`tim` và `timchu` không phân biệt hoa/thường, dấu tiếng Việt, `đ/d`, Unicode tổ hợp. Hiển thị tối đa 30 kết quả và báo khi còn kết quả khác. Bỏ qua `.git`, `node_modules`, `.venv`, file ẩn và liên kết thư mục.

`timchu` đọc theo dòng, nhận UTF-8 và encoding có BOM; chỉ đọc định dạng văn bản thông dụng tối đa 10 MB/file. Không đọc Word/PDF, file nhị phân hoặc tự chuyển VNI/TCVN3. Lọc thêm: `timchu "hoa don" *.txt`.

Mặc định mới ẩn gợi ý lệnh gốc; giữ cấu hình đã lưu trước đó. `vwt gon` / `vwt hoc` lưu lựa chọn ở `~/.vwt/config.json`. Cú pháp cũ `vwt caidat bridge tat|bat` vẫn hoạt động.

## Kiểm thử

```powershell
.\tests\test_vwt.ps1
.\tests\test_safety.ps1
.\tests\test_commands.ps1
```

Bộ kiểm thử an toàn dùng thư mục tạm riêng và mô phỏng bước xóa của Windows; không gọi Thùng rác thật, không sửa profile hoặc cấu hình người dùng. Module lưu UTF-8 có BOM để hỗ trợ Windows PowerShell 5.1.

Mã được chia thành `vwt.psm1` (lệnh nền), `commands.ps1` (lệnh bổ sung), `menu.ps1` (danh mục nhóm). Giữ ba file cùng thư mục khi sao chép dự án.

## Bộ công cụ lập trình tiếng Việt

| Công cụ | Mô tả | Link |
| :--- | :--- | :--- |
| **vpy** | Python tiếng Việt (`.vpy`) & trình soạn thảo `vide` | [cmduyeen/python-tieng-viet](https://github.com/cmduyeen/python-tieng-viet) |
| **vgit** | Git tiếng Việt cho người mới học | [cmduyeen/git-tieng-viet](https://github.com/cmduyeen/git-tieng-viet) |
| **vgh** | GitHub CLI (`gh`) tiếng Việt | [cmduyeen/github-tieng-viet](https://github.com/cmduyeen/github-tieng-viet) |
| **vwt** *(đang xem)* | Windows Terminal / PowerShell tiếng Việt | [cmduyeen/terminal-tieng-viet](https://github.com/cmduyeen/terminal-tieng-viet) |

---

Phát triển bởi [cmduyeen](https://github.com/cmduyeen) · ☕ [Mời mình 1 ly cà phê (Ko-fi)](https://ko-fi.com/cmduyeen)
