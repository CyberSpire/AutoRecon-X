#!/bin/bash

set -e

# ==========================
# Colors
# ==========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
CYAN='\033[1;34m'

echo -e "${CYAN}"
cat << "EOF"

 █████╗ ██╗   ██╗████████╗ ██████╗ ██████╗ ███████╗ ██████╗ ███╗   ██╗██╗  ██╗
██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝██╔════╝ ████╗  ██║╚██╗██╔╝
███████║██║   ██║   ██║   ██║   ██║██████╔╝█████╗  ██║      ██╔██╗ ██║ ╚███╔╝
██╔══██║██║   ██║   ██║   ██║   ██║██╔══██╗██╔══╝  ██║      ██║╚██╗██║ ██╔██╗
██║  ██║╚██████╔╝   ██║   ╚██████╔╝██║  ██║███████╗╚██████╗ ██║ ╚████║██╔╝ ██╗
╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝

                    Automated Reconnaissance Framework
                           by CyberSpire

EOF
echo -e "${NC}"

info() {
    echo -e "${BLUE}[*]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

# ==========================
# Update Packages
# ==========================

info "Updating packages..."
sudo apt update

info "Installing dependencies..."
sudo apt install -y git curl wget unzip jq python3 python3-pip

# ==========================
# Check Go Installation
# ==========================

info "Checking Go installation..."

if ! command -v go >/dev/null 2>&1; then
    error "Go is not installed."
    echo
    warning "Go 1.25.0 or newer is required."
    echo "Download the latest Go from:"
    echo "https://go.dev/dl/"
    exit 1
fi

GO_VERSION=$(go env GOVERSION | sed 's/go//')
MIN_VERSION="1.25.0"

if [ "$(printf '%s\n' "$MIN_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$MIN_VERSION" ]; then
    error "Detected Go version: $GO_VERSION"
    warning "Minimum required version: $MIN_VERSION"
    echo
    echo "Please upgrade Go and rerun the installer."
    echo "https://go.dev/dl/"
    exit 1
fi

success "Go version $GO_VERSION detected."

export PATH="$(go env GOPATH)/bin:$PATH"

echo
info "Installing Recon Tools..."

# ==========================
# Tool Installation Function
# ==========================

install_tool() {

    TOOL_NAME="$1"
    TOOL_PACKAGE="$2"

    # Extract binary name from the tool name
    BINARY=$(echo "$TOOL_NAME" | tr '[:upper:]' '[:lower:]')

    # Special case for WaybackURLs
    if [ "$TOOL_NAME" = "WaybackURLs" ]; then
        BINARY="waybackurls"
    fi

    # Special case for GoLinkFinder
    if [ "$TOOL_NAME" = "GoLinkFinder" ]; then
        BINARY="GoLinkFinder"
    fi

    if command -v "$BINARY" >/dev/null 2>&1 || [ -f "$(go env GOPATH)/bin/$BINARY" ]; then
        warning "$TOOL_NAME is already installed. Skipping..."
        return
    fi

    info "Installing $TOOL_NAME..."

    LOG_FILE=$(mktemp)

    if go install "$TOOL_PACKAGE" >"$LOG_FILE" 2>&1; then
        success "$TOOL_NAME installed successfully."
    else
        error "$TOOL_NAME installation failed."
        echo
        warning "Reason:"
        cat "$LOG_FILE"
        rm -f "$LOG_FILE"
        exit 1
    fi

    rm -f "$LOG_FILE"
}

# ==========================
# Install Recon Tools
# ==========================

install_tool "Subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"

install_tool "Assetfinder" "github.com/tomnomnom/assetfinder@latest"

info "Installing HTTPX Toolkit..."

if command -v httpx-toolkit >/dev/null 2>&1; then
    warning "HTTPX Toolkit is already installed. Skipping..."
else
    if sudo apt install -y httpx-toolkit; then
        success "HTTPX Toolkit installed successfully."
    else
        error "Failed to install HTTPX Toolkit."
        exit 1
    fi
fi

install_tool "GAU" "github.com/lc/gau/v2/cmd/gau@latest"

install_tool "WaybackURLs" "github.com/tomnomnom/waybackurls@latest"

install_tool "Katana" "github.com/projectdiscovery/katana/cmd/katana@latest"

install_tool "Hakrawler" "github.com/hakluke/hakrawler@latest"

install_tool "SubJS" "github.com/lc/subjs@latest"

install_tool "GoLinkFinder" "github.com/0xsha/GoLinkFinder@latest"

# ==========================
# Finish
# ==========================

echo
success "Installation Completed Successfully!"
echo
echo "Go binaries installed in:"
echo "$(go env GOPATH)/bin"


echo
success "Happy Hacking! 🚀"