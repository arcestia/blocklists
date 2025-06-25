#!/bin/sh

# This script merges all hosts.txt files under ./data/, removes duplicates, and generates adblock, unbound, and rpz formats
# The results are saved in ./released/

set -eu
export LC_ALL='C'

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${0:?}")" && pwd -P)"
RELEASED_DIR="$SCRIPT_DIR/released"
mkdir -p "$RELEASED_DIR"

# Find all hosts.txt files under ./data
HOSTS_FILES=$(find "$SCRIPT_DIR/data" -type f -name 'hosts.txt')

MERGED_HOSTS="$RELEASED_DIR/hosts.txt"
MERGED_ADBLOCK="$RELEASED_DIR/adblock.txt"
MERGED_UNBOUND="$RELEASED_DIR/unbound.conf"
MERGED_RPZ="$RELEASED_DIR/rpz.txt"

# Merge, normalize, deduplicate, and whitelist filtering
WHITE_LIST="$SCRIPT_DIR/white.list"
if [ -f "$WHITE_LIST" ]; then
  # Prepare whitelist as regex pattern
  awk 'NF && $1 !~ /^#/' "$WHITE_LIST" | sed 's/[\.^$*+?()[{\\|]/\\&/g' | awk '{print "^"$1"$"}' > "$RELEASED_DIR/.white_regex.tmp"
  grep -hv '^#' $HOSTS_FILES | awk 'NF {print $0}' | sed 's/\r$//' | sort | uniq | grep -v -f "$RELEASED_DIR/.white_regex.tmp" > "$MERGED_HOSTS"
  rm -f "$RELEASED_DIR/.white_regex.tmp"
else
  grep -hv '^#' $HOSTS_FILES | awk 'NF {print $0}' | sed 's/\r$//' | sort | uniq > "$MERGED_HOSTS"
fi

# Generate adblock.txt (||domain^ format)
awk 'NF && $1 !~ /^#/ {if ($2 ~ /[a-zA-Z0-9.-]+/) {printf "||%s^\n", $2} else {printf "||%s^\n", $1}}' "$MERGED_HOSTS" | sort | uniq > "$MERGED_ADBLOCK"

# Generate unbound.conf
{
  echo "# Unbound format generated from merged hosts.txt"
  awk 'NF && $1 !~ /^#/ {if ($2 ~ /[a-zA-Z0-9.-]+/) {d=$2} else {d=$1} printf "local-zone: \"%s\" static\nlocal-data: \"%s A 127.0.0.1\"\n", d, d}' "$MERGED_HOSTS"
} > "$MERGED_UNBOUND"

# Generate rpz.txt
{
  echo "; RPZ format generated from merged hosts.txt"
  echo '; $TTL 2h'
  echo "@       IN      SOA     localhost. root.localhost. ("
  echo "                        2024062501 1h 15m 30d 2h )"
  echo "        IN      NS      localhost."
  echo "; domain list below"
  awk 'NF && $1 !~ /^#/ {if ($2 ~ /[a-zA-Z0-9.-]+/) {d=$2} else {d=$1} printf "%s CNAME .\n", d}' "$MERGED_HOSTS"
} > "$MERGED_RPZ"

# Split files if they exceed 40MB
for file in "$MERGED_HOSTS" "$MERGED_ADBLOCK" "$MERGED_UNBOUND" "$MERGED_RPZ"; do
  if [ -f "$file" ] && [ $(stat -c%s "$file") -gt $((40*1024*1024)) ]; then
    base="${file%.*}"
    split -b 40m -d -a 2 --additional-suffix=.txt "$file" "${base}."
    rm "$file"
  fi
done