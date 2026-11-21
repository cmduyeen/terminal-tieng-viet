# vwt — Vietnamese Windows Terminal & Short PowerShell Commands

[Tiếng Việt](README.md) · [English](README.en.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Buy%20me%20a%20coffee-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/cmduyeen)

A safety-first PowerShell module for Windows beginners. Commands use short ASCII Vietnamese words for fast typing, with Vietnamese guides and optional PowerShell hints (`vwt hoc` / `vwt gon`).

## Quick Start

```powershell
git clone https://github.com/cmduyeen/terminal-tieng-viet.git
cd terminal-tieng-viet
Import-Module .\vwt.psm1 -Force -DisableNameChecking
vwt
```

Auto-load on PowerShell startup: `./install.ps1`. Remove auto-load: `./uninstall.ps1`.

## Highlights

- **Grouped Help Menu (`vwt`):** `vwt di` (navigation), `vwt file` (files), `vwt timkiem` (search), `vwt zip` (archives), `vwt may` (system), `vwt net` (network), `vwt giup` (help).
- **Accent-Insensitive Search:** `tim` and `timchu` match Vietnamese text regardless of tone marks, `đ/d`, or Unicode normalization.
- **Safety Defaults:**
  - Copy/move/compress refuse to overwrite existing destinations.
  - Archive extraction validates all paths against zip-slip and enforces size/item limits.
  - Delete (`xoa`) sends files to the Windows Recycle Bin with confirmation and blocks system/root/home directories.

## Tests

```powershell
.\tests\test_vwt.ps1
.\tests\test_safety.ps1
.\tests\test_commands.ps1
```

## Vietnamese CLI Ecosystem

| Tool | Description | Repository |
| :--- | :--- | :--- |
| **vpy** | Vietnamese Python (`.vpy`) & `vide` editor | [cmduyeen/python-tieng-viet](https://github.com/cmduyeen/python-tieng-viet) |
| **vgit** | Vietnamese Git CLI for beginners | [cmduyeen/git-tieng-viet](https://github.com/cmduyeen/git-tieng-viet) |
| **vgh** | Vietnamese GitHub CLI (`gh`) | [cmduyeen/github-tieng-viet](https://github.com/cmduyeen/github-tieng-viet) |
| **vwt** *(current)* | Vietnamese Windows Terminal / PowerShell commands | [cmduyeen/terminal-tieng-viet](https://github.com/cmduyeen/terminal-tieng-viet) |

---

Developed by [cmduyeen](https://github.com/cmduyeen) · ☕ [Buy me a coffee (Ko-fi)](https://ko-fi.com/cmduyeen)
