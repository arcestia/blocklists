#!/bin/sh
# This script finds dead domains in all .txt filter files using dead-domains-linter and exports the dead domains to released/dead-domains.txt
# Requires: npm i -g @adguard/dead-domains-linter

set -eu
export LC_ALL='C'

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${0:?}")" && pwd -P)"
RELEASED_DIR="$SCRIPT_DIR/released"
mkdir -p "$RELEASED_DIR"

# Usage: ./dead_domains_filter.sh [input_file] [output_file]
INPUT_FILE="${1:-$SCRIPT_DIR/../dead-domains.txt}"
OUTPUT_FILE="${2:-$SCRIPT_DIR/../confirmed-dead-domains.txt}"

# Confirm truly dead by DNS check
> "$OUTPUT_FILE"
while IFS= read -r domain; do
  [ -z "$domain" ] && continue
  [ "${domain#\#}" != "$domain" ] && continue
  if command -v dig >/dev/null 2>&1; then
    dig +short "$domain" | grep -q '[a-zA-Z0-9]' || echo "$domain" >> "$OUTPUT_FILE"
  elif command -v nslookup >/dev/null 2>&1; then
    nslookup "$domain" >/dev/null 2>&1 || echo "$domain" >> "$OUTPUT_FILE"
  else
    echo "Neither dig nor nslookup found. Please install one." >&2
    exit 1
  fi
done < "$INPUT_FILE"

echo "Confirmed dead domains exported to $OUTPUT_FILE"

# Now confirm truly dead by DNS check
echo "" > "$SCRIPT_DIR/../dead-domains.txt"
while IFS= read -r domain; do
  [ -z "$domain" ] && continue
  [ "${domain#\#}" != "$domain" ] && continue
  if command -v dig >/dev/null 2>&1; then
    dig +short "$domain" | grep -q '[a-zA-Z0-9]' || echo "$domain" >> "$SCRIPT_DIR/../dead-domains.txt"
  elif command -v nslookup >/dev/null 2>&1; then
    nslookup "$domain" >/dev/null 2>&1 || echo "$domain" >> "$SCRIPT_DIR/../dead-domains.txt"
  else
    echo "Neither dig nor nslookup found. Please install one." >&2
    exit 1
  fi
done < "$SCRIPT_DIR/../dead-domains.txt.tmp"
rm -f "$SCRIPT_DIR/../dead-domains.txt.tmp"

# Clean up per-file dead lists
rm -f "$RELEASED_DIR"/dead-domains.*.txt

echo "Confirmed dead domains exported to $SCRIPT_DIR/../dead-domains.txt"
