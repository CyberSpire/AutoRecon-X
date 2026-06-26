#!/bin/bash

set -e

echo "[*] Updating packages..."
sudo apt update

echo "[*] Installing dependencies..."
sudo apt install -y git curl wget unzip jq python3 python3-pip

echo "[*] Installing Go (if not installed)..."
if ! command -v go >/dev/null; then
    sudo apt install -y golang
fi

export PATH=$PATH:$(go env GOPATH)/bin

echo "[*] Installing Recon Tools..."

go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

go install github.com/tomnomnom/assetfinder@latest

go install github.com/projectdiscovery/httpx/cmd/httpx@latest

go install github.com/lc/gau/v2/cmd/gau@latest

go install github.com/tomnomnom/waybackurls@latest

go install github.com/projectdiscovery/katana/cmd/katana@latest

go install github.com/hakluke/hakrawler@latest

go install github.com/lc/subjs@latest

go install github.com/0xsha/GoLinkFinder@latest

echo ""
echo "[✓] Installation Completed Successfully!"
echo ""
echo "Go binaries installed in:"
echo "$(go env GOPATH)/bin"
echo ""
echo "Make sure this path is added to your PATH variable."