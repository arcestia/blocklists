#!/bin/sh
# This script finds dead domains in all .txt filter files using dead-domains-linter and exports the dead domains to released/dead-domains.txt
# Requires: npm i -g @adguard/dead-domains-linter

set -eu
export LC_ALL='C'

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${0:?}")" && pwd -P)"
RELEASED_DIR="$SCRIPT_DIR/released"
mkdir -p "$RELEASED_DIR"

# Find all hosts.txt and hosts.*.txt files in released/ and data/
HOSTS_FILES=$(find "$SCRIPT_DIR/released" -type f \( -name 'hosts.txt' -o -name 'hosts.*.txt' \))

# Run dead-domains-linter in export mode for all found hosts files
for file in $HOSTS_FILES; do
  base=$(basename "$file" .txt)
  deadfile="$RELEASED_DIR/dead-domains.$base.txt"
  dead-domains-linter -i "$file" --dnscheck=false --export="$deadfile"
done

# Optionally, combine all dead domains into one file
echo "" > "$RELEASED_DIR/dead-domains.txt"
cat "$RELEASED_DIR"/dead-domains.*.txt | grep -v '^$' | sort | uniq > "$RELEASED_DIR/dead-domains.txt"

# Clean up per-file dead lists
rm -f "$RELEASED_DIR"/dead-domains.*.txt

echo "Dead domains exported to $RELEASED_DIR/dead-domains.txt"
