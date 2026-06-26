#!/bin/bash

tools=(
subfinder
assetfinder
httpx
gau
waybackurls
katana
hakrawler
subjs
GoLinkFinder
curl
)

echo "Checking installed tools..."
echo ""

missing=0

for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "[✓] $tool"
    else
        echo "[✗] $tool"
        missing=1
    fi
done

echo ""

if [ $missing -eq 0 ]; then
    echo "All required tools are installed."
else
    echo "Some tools are missing."
fi