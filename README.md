# 🚀 AutoReconX

### Automated Bug Bounty Recon Framework

**AutoReconX** is a fast and automated reconnaissance framework designed for Bug Bounty Hunters and Penetration Testers. It automates the entire recon workflow—from subdomain enumeration to URL collection, JavaScript discovery, endpoint extraction, and parameter gathering—allowing researchers to focus on finding vulnerabilities instead of running tools manually.

---

## ✨ Features

- 🔍 Automated Subdomain Enumeration
- 🌐 Live Host Detection
- 🎯 High-Value Asset Filtering
- 📂 URL Collection from Multiple Sources
- 📜 JavaScript File Discovery
- 🔗 Endpoint & Link Extraction
- ⚙️ Parameter Discovery
- 🚀 Parallel Processing
- 📊 Detailed Recon Summary
- 📁 Organized Output Structure
- 💾 Resume Capability (Skips Completed Stages)

---

## 📦 Tools Used

| Tool | Purpose |
|------|---------|
| Subfinder | Passive Subdomain Enumeration |
| Assetfinder | Additional Subdomain Discovery |
| Httpx | Live Host Detection |
| GAU | Historical URL Collection |
| Waybackurls | Wayback Machine URLs |
| Katana | Web Crawling |
| Hakrawler | Link Crawling |
| SubJS | JavaScript File Discovery |
| GoLinkFinder | Endpoint Extraction |
| curl | Redirect Resolution |

---

## ⚡ Usage

### Scan a Single Target

```bash
./autoreconx.sh --target example.com
```

---

### Scan Multiple Targets (Scope File)

Create a file named `scope.txt`:

```text
*.example.com
*.target.com
api.company.com
portal.company.com
```

Then run:

```bash
./autoreconx.sh --scope scope.txt
```

---

## Installation

Clone the repository

```bash
git clone https://github.com/CyberSpire/AutoRecon-X.git
cd AutoRecon-X
```

Install all dependencies

```bash
chmod +x requirements.sh
./requirements.sh
```

Run

```bash
chmod +x autoreconx.sh
./autoreconx.sh --target example.com
```


## 📂 Output Structure

```
run_DATE/
│
├── subs/
│   ├── all_subs.txt
│   ├── live_hosts.txt
│   ├── high_value_hosts.txt
│   ├── low_value_hosts.txt
│   └── clean_domains.txt
│
├── urls/
│   ├── gau.txt
│   ├── wayback.txt
│   ├── final_urls.txt
│   └── extracted_links.txt
│
├── js/
│   ├── js_files_collected.txt
│   ├── js_from_katana.txt
│   └── final_js_files.txt
│
├── params/
│   └── params.txt
│
└── scans/
```

---

## 🔄 Workflow

```
Target / Scope
       │
       ▼
Subdomain Enumeration
       │
       ▼
Live Host Detection
       │
       ▼
High-Value Asset Filtering
       │
       ▼
URL Collection
   ├── GAU
   ├── Waybackurls
   ├── Katana
   └── Hakrawler
       │
       ▼
JavaScript Discovery
       │
       ▼
Endpoint Extraction
       │
       ▼
Parameter Discovery
       │
       ▼
Recon Summary
```

---

## 🤝 Contributing

Contributions, improvements, and feature requests are welcome.

Feel free to fork the repository and submit a Pull Request.

---

## ⚠️ Disclaimer

This project is intended **only for authorized security testing, bug bounty programs, and educational purposes.**

The author is **not responsible** for any misuse or unauthorized activities performed using this tool.

---

## ⭐ If you find this project useful, consider giving it a star!
