# ------------ Recon Script (Enhanced) -------------
#!/bin/bash

set -e
RED='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
CYAN='\033[1;34m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'

START_TIME=$(date +%s)

# =======================================
# Parse input arguments
# =======================================
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --scope)
      SCOPE_FILE="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}[!] Unknown argument: $1${NC}"
      echo -e "${CYAN}Usage:${NC}"
      echo -e "${WHITE}  $0 --target domain.com${NC}"
      echo -e "${WHITE}  $0 --scope scope.txt${NC}"
      exit 1
      ;;
  esac
done


# Check for incorrect --target usage
if [[ -n "$TARGET" && "$TARGET" == *.txt ]]; then
    echo -e "${RED}[!] It looks like you used --target with a file: '$TARGET'${NC}"
    echo -e "${CYAN}    Did you mean to use --scope instead?${NC}"
    echo -e "${WHITE}    Use:${NC} $0 --target example.com  ${NC}"
    echo -e "${WHITE}    Or :${NC} $0 --scope scope.txt      ${NC}"
    exit 1
fi

if [[ -z "$TARGET" && -z "$SCOPE_FILE" ]]; then
  echo -e "${RED}[!] No input provided.${NC}"
  echo -e "${CYAN}Usage:${NC}"
  echo -e "${WHITE}  $0 --target domain.com${NC}"
  echo -e "${WHITE}  $0 --scope scope.txt${NC}"
  exit 1
fi

# =======================================
# Directory Setup
# =======================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TODAY=$(date +%F)

WORK_DIR="$SCRIPT_DIR/run_$TODAY"
# TOOLS_DIR="$HOME/tools"
mkdir -p "$WORK_DIR"/{subs,urls,scans,params,js}

ALL_SUBS="$WORK_DIR/subs/all_subs.txt"
LIVE="$WORK_DIR/subs/live_hosts.txt"

# =======================================
# Subdomain Enumeration
# =======================================

if [[ -s "$ALL_SUBS" ]]; then
    echo -e "${YELLOW}[!] Subdomain list already exists. Skipping Subdomain Enumeration.${NC} -> $ALL_SUBS"
else
    if [ -n "$SCOPE_FILE" ]; then
        echo -e "${MAGENTA}[*] Processing scope file...${NC}"
        while IFS= read -r DOMAIN || [ -n "$DOMAIN" ]; do
            DOMAIN=$(echo "$DOMAIN" | tr -d ' ')  # Remove spaces and newlines
            if [[ "$DOMAIN" == \*.* ]]; then  # Detect wildcard domain
                ROOT=$(echo "$DOMAIN" | sed 's/*\.//')  # Remove the wildcard prefix
                echo -e "[+] Wildcard domain: $DOMAIN — Running SubFinder & Assetfinder..."
                subfinder -d "$ROOT" -silent >> "$ALL_SUBS"
                assetfinder --subs-only "$ROOT" >> "$ALL_SUBS"
            else
                echo -e "[!] No wildcard domain: $DOMAIN — Skipping Subdomain Enumeration"
                echo "$DOMAIN" >> "$ALL_SUBS"
            fi
        done < "$SCOPE_FILE"
    else
        echo -e "${MAGENTA}[*] Running subfinder on $TARGET...${NC}"
        subfinder -d "$TARGET" -silent >> "$ALL_SUBS"
        assetfinder --subs-only "$TARGET" >> "$ALL_SUBS"
    fi
    sort -u "$ALL_SUBS" -o "$ALL_SUBS"
    echo -e "${GREEN}[DONE] Successfully Performed Subdomain Enumeration. ${NC}"
    echo -e "${YELLOW}  • Found ${RED}$(wc -l < "$ALL_SUBS")${YELLOW} Subdomains${NC}"
fi

# =======================================
# Live Host Probing
# =======================================
if [[ -s "$LIVE" ]]; then
  echo -e "${YELLOW}[!] Live hosts file already exists. Skipping Httpx.${NC} -> $LIVE"
else
  echo -e "${MAGENTA}[*] Probing live hosts...${NC}"
  cat "$ALL_SUBS" | httpx-toolkit -silent > "$LIVE"
  echo -e "${YELLOW}  • Found ${RED}$(wc -l < "$LIVE")${YELLOW} Live Subdomains${NC}"
fi

# =======================================
# Separate High and Low Value Hosts
# =======================================
if [[ ! -s "filter_keywords.txt" ]]; then
  echo -e "${RED}[!] filter_keywords.txt is missing or empty. Exiting.${NC}"
  exit 1
fi

KEYWORDS=$(paste -sd'|' filter_keywords.txt)
# echo -e "${YELLOW}[DEBUG] Keywords loaded: $KEYWORDS${NC}"
if [[ -z "$KEYWORDS" ]]; then
  echo -e "${RED}[!] No keywords loaded from filter_keywords.txt. Exiting.${NC}"
  exit 1
fi

HIGH_VALUE="$WORK_DIR/subs/high_value_hosts.txt"
LOW_VALUE="$WORK_DIR/subs/low_value_hosts.txt"

grep -iE "$KEYWORDS" "$LIVE" > "$HIGH_VALUE"
grep -ivE "$KEYWORDS" "$LIVE" > "$LOW_VALUE"

echo -e "${MAGENTA}[+] High-value subdomains: ${NC}$(wc -l < "$HIGH_VALUE")"
echo -e "${MAGENTA}[+] Low-value subdomains:  ${NC}$(wc -l < "$LOW_VALUE")"

#echo "[DEBUG] Host categorization completed successfully"

# =======================================
# Cleaning Domains (High/High+Low)
# =======================================

CLEAN_DOMAINS="$WORK_DIR/subs/clean_domains.txt"

echo -e "${CYAN}[*] SELECT WHICH HOST SCAN TO PRIORITIZE:${NC}"
echo -e "  1) Only High-Value Hosts (Default)"
echo -e "  2) Both High-Value and Low-Value Hosts"
read -p "Enter choice [1/2]: " choice

CLEAN_DOMAINS="$WORK_DIR/subs/clean_domains.txt"

if [[ "$choice" == "2" ]]; then
    #echo -e "${MAGENTA}[*] Cleaning Domain list from both High and Low Value...${NC}"
    cat "$HIGH_VALUE" "$LOW_VALUE" | sed -E 's@https?://@@' | cut -d'/' -f1 | sort -u > "$CLEAN_DOMAINS"
else
    #echo -e "${MAGENTA}[*] Cleaning Domain list from High Value only...${NC}"
    cat "$HIGH_VALUE" | sed -E 's@https?://@@' | cut -d'/' -f1 | sort -u > "$CLEAN_DOMAINS"
fi

#echo -e "${GREEN}[DONE] Cleaned domains saved to ${NC} -> $CLEAN_DOMAINS"

# ================================================================================
# Parallel URL Collection - GAU + Wayback + Katana + Hakrawler + UrlFinder
# ================================================================================

WB_OUT="$WORK_DIR/urls/wayback.txt"
GAU_OUT="$WORK_DIR/urls/gau.txt"
KT_OUT="$WORK_DIR/urls/kt_raw.txt"
HK_OUT="$WORK_DIR/urls/hk_raw.txt"
FINAL_OUT="$WORK_DIR/urls/final_urls.txt"

echo -e "${MAGENTA}\n[*] Processing URL Collection.${NC}"
if [[ -s "$FINAL_OUT" ]]; then
    echo -e "${YELLOW}[!] URL Collection Already Done. Skipping...${NC} -> $FINAL_OUT"
else
    echo -e "${MAGENTA}[*] Collecting URLs via Gau, Waybackurls, Hakrawler & Katana...${NC}"

    # Clear existing raw output
    > "$GAU_OUT" > "$WB_OUT" > "$KT_OUT" > "$HK_OUT" > "$FINAL_OUT"

    collect_urls() {
        domain="$1"
        echo "[*] Processing: $domain"

        # GAU
        timeout 80s gau "$domain" 2>/dev/null >> "$GAU_OUT"

        # WAYBACKURLS
        echo "$domain" | timeout 90s waybackurls 2>/dev/null >> "$WB_OUT"

        # Katana with depth
        timeout 80s katana -u "https://$domain" -d 5 -silent 2>/dev/null >> "$KT_OUT"

        # Hakrawler with subs
        final_url=$(curl -Ls -o /dev/null -w %{url_effective} "https://$domain")
        echo "$final_url" | timeout 70s hakrawler -d 2 -subs 2>/dev/null >> "$HK_OUT"

        # urlfinder (all sources, strict scope)
        # timeout 60s urlfinder -d "$domain" -silent -fs rdn 2>/dev/null | grep -Eo 'https?://[^ ]+' | grep -vE '\.css$|\.jpg$|\.png$|\.svg$|\.woff|mailto:|javascript:' >> "$UF_OUT"

        # Cariddi (deep & secrets hunt)
        # timeout 60s cariddi "https://$domain" -intensive -e -info -s -err -ext 3 -plain 2>/dev/null >> "$CRD_OUT"
        wait    
}

    export -f collect_urls
    export GAU_OUT WB_OUT KT_OUT HK_OUT
    cat "$CLEAN_DOMAINS" | xargs -P 10 -I {} bash -c 'collect_urls "$@"' _ {}

    # Merge Results
    echo "[*] Merging Results..."
    cat "$GAU_OUT" "$WB_OUT" "$KT_OUT" "$HK_OUT" | sort -u > "$FINAL_OUT"
    echo -e "${GREEN}[DONE] Final URLs saved to ${NC} -> $FINAL_OUT"
fi

# =======================================
# JS File Collection - SubJS + Katana
# =======================================
JS_DIR="$WORK_DIR/js"
mkdir -p "$JS_DIR"

JS_OUTPUT="$JS_DIR/js_files_collected.txt"
JS_KATANA="$JS_DIR/js_from_katana.txt"
COMBINED_JS="$JS_DIR/final_js_files.txt"

echo -e "${MAGENTA}[*] Processing JS Collection...${NC}"

# Check if the live hosts file exists and is not empty
if [[ ! -s "$LIVE" ]]; then
    echo -e "${RED}[!] Live hosts file is missing or empty. Please check the file: $LIVE_HOSTS${NC}"
    exit 1
fi

# Step 1: JS collection from live hosts using subjs
if [[ -s "$JS_OUTPUT" ]]; then
    echo -e "${YELLOW}[!] JS files already collected. Skipping... ${NC} -> $JS_OUTPUT"
else
    # Run subjs with the domains from live hosts file and collect JS files in real-time
    cat "$LIVE" | subjs | sort -u >> "$JS_OUTPUT"

    # Check if JS files were collected
    if [[ -s "$JS_OUTPUT" ]]; then
        echo -e "${GREEN}[+] JS files collection completed. Results saved to ${NC} -> $JS_OUTPUT"
    else
        echo -e "${RED}[!] No JS files found. Please check the output for errors.${NC}"
    fi
fi

# Step 2: Extract JS URLs from Katana output
if [[ -s "$KT_OUT" ]]; then
    grep -Ei "\.js(\?.*)?$" "$KT_OUT" | sort -u > "$JS_KATANA"
    echo -e "${GREEN}[+] JS files extracted from Katana Output.${NC}"
else
    echo -e "${RED}[!] Katana output file not found or empty: $KT_OUT${NC}"
fi

# Step 3: Merge both JS results
cat "$JS_OUTPUT" "$JS_KATANA" | sort -u > "$COMBINED_JS"
echo -e "${GREEN}[DONE] Combined JS files saved to ${NC} -> $COMBINED_JS"

# =======================================
# Link Extraction - GoLinkFinder
# =======================================

LINKS_OUTPUT="$WORK_DIR/urls/extracted_links.txt"
TEMP_LINKS="$WORK_DIR/urls/temp_links.txt"

echo -e "${MAGENTA}[*] Processing Link Extraction...${NC}"

# Check if the live hosts file exists and is not empty
if [[ ! -s "$LIVE" ]]; then
    echo -e "${RED}[!] Live hosts file is missing or empty. Please check the file: $LIVE_HOSTS${NC}"
    exit 1
fi

# Check if links were already extracted
if [[ -s "$LINKS_OUTPUT" ]]; then
    echo -e "${YELLOW}[!] Extracted links already exist. Skipping ...${NC} -> $LINKS_OUTPUT"
else
    # Process each live domain
    while read -r domain; do
        [[ -z "$domain" ]] && continue
        echo -e "${CYAN}[*] Extracting links from: $domain${NC}"

        # Run GoLinkFinder and write to temporary file
        if GoLinkFinder -d "$domain" > "$TEMP_LINKS" 2>/dev/null; then
            while read -r link; do
                [[ -z "$link" ]] && continue

                # If it's already a full URL, keep it
                if [[ "$link" =~ ^https?:// ]]; then
                    echo "$link"
                else
                    # Sanitize and prepend domain to relative path
                    clean_link=$(echo "$link" | sed 's#^[./]*##')
                    echo "https://$domain/$clean_link"
                fi
            done < "$TEMP_LINKS" >> "$LINKS_OUTPUT"
        else
            echo -e "${RED}[!] Error processing $domain. Skipping...${NC}"
        fi
    done < "$LIVE"

    # Final check
    if [[ -s "$LINKS_OUTPUT" ]]; then
        echo -e "${GREEN}[DONE] Links extraction completed. Results saved to ${NC} -> $LINKS_OUTPUT"
    else
        echo -e "${RED}[!] No links extracted. Please check manually.${NC}"
    fi
fi

# =======================================
# Params Extraction 
# =======================================

PARAM_URLS="$WORK_DIR/params/params.txt"

echo -e "${MAGENTA}[*] Filtering URLs having parameters...${NC}"

# Check if file already exists and is not empty
if [[ -s "$PARAM_URLS" ]]; then
    echo -e "${YELLOW}[!] URLs with Parameters Already Extracted. Skipping...${NC} -> $PARAM_URLS"
else
    cat "$FINAL_OUT" | grep '?' | grep '=' | sort -u > "$PARAM_URLS"

    if [[ -s "$PARAM_URLS" ]]; then
        echo -e "${GREEN}[DONE] URLs with Parameters Extracted Successfully. Saved to${NC} -> $PARAM_URLS"
    else
        echo -e "${RED}[!] No URLs with Parameters Found.${NC}"
    fi
fi

# =======================================
# Recon Summary
# =======================================

echo -e "\n${GREEN}[+] Recon Summary:${NC}"
echo -e "${YELLOW}  • Subdomains: ${NC}$(wc -l < "$ALL_SUBS")"
echo -e "${YELLOW}  • Live Hosts: ${NC}$(wc -l < "$LIVE")"
echo -e "${YELLOW}  • Wayback URLs: ${NC}$(wc -l < "$WB_OUT")"
echo -e "${YELLOW}  • GAU URLs: ${NC}$(wc -l < "$GAU_OUT")"
echo -e "${YELLOW}  • Katana URLs: ${NC}$(wc -l < "$KT_OUT")"
echo -e "${YELLOW}  • FINAL URLs: ${NC}$(wc -l < "$FINAL_OUT")"
echo -e "${YELLOW}  • JS Files: ${NC}$(wc -l < "$COMBINED_JS")"
echo -e "${YELLOW}  • Extracted Links: ${NC}$(wc -l < "$LINKS_OUTPUT")"
echo -e "${YELLOW}  • Params: ${NC}$(wc -l < "$PARAM_URLS")"

END_TIME=$(date +%s)
RUNTIME=$((END_TIME - START_TIME))
if (( RUNTIME >= 60 )); then
    MINUTES=$(( RUNTIME / 60 ))
    SECONDS=$(( RUNTIME % 60 ))
    echo -e "\n${GREEN}[✓] Recon completed in ${RED}${MINUTES} min ${SECONDS} sec.${NC}"
else
    echo -e "\n${GREEN}[DONE] Recon completed in ${RUNTIME} seconds.${NC}"
fi
echo -e "${GREEN}    Results saved in:${NC} $WORK_DIR"
