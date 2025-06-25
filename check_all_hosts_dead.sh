#!/bin/sh
# This script checks all domains in all hosts.txt and hosts.*.txt files in the released/ directory to see if they are actually dead (DNS lookup).
# Outputs a deduplicated list of truly dead domains to dead-domains.txt in the project root.

set -eu
export LC_ALL='C'

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${0:?}")" && pwd -P)"
RELEASED_DIR="$SCRIPT_DIR/released"
OUTPUT_FILE="$SCRIPT_DIR/../dead-domains.txt"

# Find all hosts.txt and hosts.*.txt files in released/
HOSTS_FILES=$(find "$RELEASED_DIR" -type f \( -name 'hosts.txt' -o -name 'hosts.*.txt' \))

# Collect all domains (deduped, ignore comments/blank lines)
echo "" > "$SCRIPT_DIR/all_domains.tmp"
for file in $HOSTS_FILES; do
  awk 'NF && $1 !~ /^#/ {if ($2 ~ /[a-zA-Z0-9.-]+/) {print $2} else {print $1}}' "$file"
done | sort | uniq > "$SCRIPT_DIR/all_domains.tmp"

# Use massdns for efficient DNS checking
# Requires: massdns (https://github.com/blechschmidt/massdns) and a resolvers.txt file in the script directory
# If you do not have resolvers.txt, you can get one from the massdns repo or generate your own list of public DNS resolvers.

if ! command -v massdns >/dev/null 2>&1; then
  echo "massdns not found. Please install massdns: https://github.com/blechschmidt/massdns" >&2
  exit 1
fi
if [ ! -f "$SCRIPT_DIR/resolvers.txt" ]; then
  echo "resolvers.txt not found in $SCRIPT_DIR. Please provide a list of DNS resolvers." >&2
  exit 1
fi

# Prepare massdns input (one domain per line)
mv "$SCRIPT_DIR/all_domains.tmp" "$SCRIPT_DIR/all_domains.massdns"

# Run massdns (A record lookup, simple output)
massdns -r "$SCRIPT_DIR/resolvers.txt" -t A -o S "$SCRIPT_DIR/all_domains.massdns" > "$SCRIPT_DIR/massdns_output.txt"

# Domains resolved are in massdns_output.txt (format: domain. A ...)
# Domains not resolved will not appear in output, so we diff the input and output to get dead domains
awk '{print $1}' "$SCRIPT_DIR/massdns_output.txt" | sed 's/\.$//' | sort | uniq > "$SCRIPT_DIR/massdns_alive.txt"

sort "$SCRIPT_DIR/all_domains.massdns" | uniq > "$SCRIPT_DIR/all_domains.sorted.txt"
comm -23 "$SCRIPT_DIR/all_domains.sorted.txt" "$SCRIPT_DIR/massdns_alive.txt" > "$OUTPUT_FILE"

rm -f "$SCRIPT_DIR/all_domains.massdns" "$SCRIPT_DIR/all_domains.sorted.txt" "$SCRIPT_DIR/massdns_output.txt" "$SCRIPT_DIR/massdns_alive.txt"
echo "Truly dead domains exported to $OUTPUT_FILE (checked with massdns)"
