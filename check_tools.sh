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

RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[1;34m'
CYAN=$'\033[1;36m'
WHITE=$'\033[1;37m'
NC=$'\033[0m'

cat <<EOF
${CYAN}

 █████╗ ██╗   ██╗████████╗ ██████╗ ██████╗ ███████╗ ██████╗ ███╗   ██╗██╗  ██╗
██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝██╔════╝ ████╗  ██║╚██╗██╔╝
███████║██║   ██║   ██║   ██║   ██║██████╔╝█████╗  ██║      ██╔██╗ ██║ ╚███╔╝
██╔══██║██║   ██║   ██║   ██║   ██║██╔══██╗██╔══╝  ██║      ██║╚██╗██║ ██╔██╗
██║  ██║╚██████╔╝   ██║   ╚██████╔╝██║  ██║███████╗╚██████╗ ██║ ╚████║██╔╝ ██╗
╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝
${GREEN}               Automated Reconnaissance Framework${NC}
${YELLOW}                      ~ By ${WHITE}CyberSpire${NC}

EOF

echo -e "${YELLOW}Checking installed tools...${NC}"
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
    echo -e "${GREEN}All required tools are installed.${NC}"
else
    echo -e "${RED}Some tools are missing.${NC}"
fi