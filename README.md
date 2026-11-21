# 💻 terminal-tieng-viet (`vwt`) — Terminal & PowerShell tiếng Việt an toàn cho Windows

[Tiếng Việt](README.md) · [English](README.en.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-Windows%205.1%2B%20%2F%207%2B-blue.svg)](https://learn.microsoft.com/powershell/)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Buy%20me%20a%20coffee-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/cmduyeen)

Module PowerShell dành cho người Việt mới làm quen với Windows Terminal. Lệnh **viết không dấu để gõ siêu nhanh** (`nha`, `lietke`, `tim`, `nen`, `xoa`), còn hướng dẫn **có dấu rõ ràng** để đọc là hiểu ngay.

## ✨ Điểm nổi bật

- **Tìm file & tìm chữ tiếng Việt không phân biệt dấu:** Gõ `tim "hoa don"` vẫn tìm ra file tên `"Hóa đơn.pdf"`; `timchu "duong den"` tìm ra cả `"đường đến"`.
- **An toàn mặc định — chống lỡ tay mất dữ liệu:**
  - `xoa` luôn hỏi xác nhận, chặn xóa nhầm ổ đĩa gốc / thư mục hệ thống / thư mục cá nhân, và chỉ đưa vào **Thùng rác Windows** (không dùng lệnh xóa vĩnh viễn).
  - `chep`, `chuyen`, `nen` tự dừng nếu file đích đã tồn tại (không ghi đè âm thầm).
  - `giainen` kiểm tra chống lỗi bảo mật thoát thư mục (zip-slip) và giới hạn dung lượng an toàn.
- **Menu phân nhóm trực quan (`vwt`):** Quên lệnh chỉ cần gõ `vwt` hoặc `vwt file`, `vwt timkiem` để xem hướng dẫn ngay trong terminal.
- **Vừa dùng vừa học PowerShell (`vwt hoc` / `vwt gon`):** Tùy chọn hiện gợi ý lệnh PowerShell gốc nếu bạn muốn học sâu hơn.

---

## ⚡ Bắt đầu trong 30 giây

```powershell
git clone https://github.com/cmduyeen/terminal-tieng-viet.git
cd terminal-tieng-viet

# Dùng thử ngay
Import-Module .\vwt.psm1 -Force -DisableNameChecking
vwt
```

Muốn mỗi lần mở PowerShell tự có sẵn `vwt`: chạy `./install.ps1` (gỡ bỏ bằng `./uninstall.ps1`).

---

## 🚀 Thực hành nhanh

```powershell
ban                       # Nhảy nhanh tới Desktop
lietke                    # Xem danh sách file, thư mục
taothumuc "Bai tap"       # Tạo thư mục mới
vao "Bai tap"             # Vào thư mục vừa tạo
tim "hoa don"             # Tìm file theo tên (không cần gõ dấu)
timchu "duong den" *.txt  # Tìm chữ bên trong các file .txt
nen "Bai tap"             # Nén thành Bai tap.zip
xoa "nhap.txt"            # Chuyển vào Thùng rác (có hỏi xác nhận)
```

> 💡 **Làm việc tiếp ngay trong thư mục vừa tạo:** Viết code Python với [`vpy` (python-tieng-viet)](https://github.com/cmduyeen/python-tieng-viet), lưu phiên bản bằng [`vgit` (git-tieng-viet)](https://github.com/cmduyeen/git-tieng-viet) (`vgit batdau`, `vgit luu`) hoặc tạo repo GitHub với [`vgh` (github-tieng-viet)](https://github.com/cmduyeen/github-tieng-viet).

---

## 📖 Nhóm lệnh & Công cụ chính

### Menu hướng dẫn theo nhóm
Gõ `vwt` để xem toàn bộ, hoặc gõ số/tên ngắn:
`vwt di` (1 - đi lại) · `vwt file` (2 - file & nội dung) · `vwt timkiem` (3 - tìm kiếm) · `vwt zip` (4 - nén/giải nén) · `vwt may` (5 - máy tính) · `vwt net` (6 - mạng) · `vwt giup` (7 - trợ giúp).

### Các lệnh hay dùng nhất

| Lệnh | Công dụng |
| :--- | :--- |
| `nha` / `ban` / `tailieu` | Về thư mục Cá nhân / Desktop / Documents |
| `vao "Tài liệu"` / `lui` | Vào thư mục / lùi ra 1 cấp |
| `lietke` / `cay` | Xem danh sách / xem cây thư mục 2 cấp |
| `dangodau` / `dungluong` | Xem đường dẫn hiện tại / tính dung lượng thư mục |
| `taothumuc` / `taofile` | Tạo thư mục / tạo file trống |
| `xemfile` / `dau` / `cuoi` | Đọc file / xem 10 dòng đầu / xem 10 dòng cuối |
| `chep` / `chuyen` / `doiten` | Chép / chuyển / đổi tên an toàn (không ghi đè) |
| `xoa` | Chuyển vào Thùng rác Windows (luôn hỏi xác nhận) |
| `tim` / `timchu` | Tìm file / tìm nội dung không phân biệt dấu tiếng Việt |
| `nen` / `giainen` | Nén `.zip` / giải nén an toàn |
| `odia` / `maytinh` / `mang` | Xem ổ đĩa / thông tin máy / kết nối mạng |
| `pingthu <web>` / `tientrinh` | Kiểm tra mạng / xem tiến trình đang chạy |
| `vwt hoc` / `vwt gon` | Bật/tắt gợi ý lệnh PowerShell gốc |

---

## 🧪 Kiểm thử an toàn

```powershell
.\tests\test_vwt.ps1
.\tests\test_safety.ps1
.\tests\test_commands.ps1
```

*(Bộ test dùng thư mục tạm riêng và mô phỏng bước xóa Windows, không tác động tới dữ liệu thật.)*

---

## 🧰 Bộ công cụ lập trình tiếng Việt

| Công cụ | Mô tả | Link |
| :--- | :--- | :--- |
| **python-tieng-viet** | Python tiếng Việt (`vpy`) & trình soạn thảo `vide` | [cmduyeen/python-tieng-viet](https://github.com/cmduyeen/python-tieng-viet) |
| **git-tieng-viet** | Git tiếng Việt (`vgit`) cho người mới học | [cmduyeen/git-tieng-viet](https://github.com/cmduyeen/git-tieng-viet) |
| **github-tieng-viet** | GitHub CLI tiếng Việt (`vgh`) | [cmduyeen/github-tieng-viet](https://github.com/cmduyeen/github-tieng-viet) |
| **terminal-tieng-viet** *(đang xem)* | Windows Terminal / PowerShell tiếng Việt (`vwt`) | [cmduyeen/terminal-tieng-viet](https://github.com/cmduyeen/terminal-tieng-viet) |

---

[MIT License](LICENSE) · Phát triển bởi [cmduyeen](https://github.com/cmduyeen) · ☕ [Mời mình 1 ly cà phê (Ko-fi)](https://ko-fi.com/cmduyeen)
