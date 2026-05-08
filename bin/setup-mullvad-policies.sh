#!/bin/sh

# Install Mullvad Browser policies.json for unified extension management.

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
POLICIES_SRC="${DOTFILES_DIR}/mullvad-policies/policies.json"
POLICIES_DST="/opt/mullvad-browser/distribution/policies.json"

if [ ! -f "$POLICIES_SRC" ]; then
  echo "Source policies.json not found: $POLICIES_SRC" >&2
  exit 1
fi

if [ ! -d "/opt/mullvad-browser/distribution" ]; then
  echo "Mullvad Browser distribution directory not found." >&2
  echo "Is Mullvad Browser installed?" >&2
  exit 1
fi

echo "Installing policies.json to Mullvad Browser..."
echo "  Source: $POLICIES_SRC"
echo "  Target: $POLICIES_DST"
echo ""

sudo cp "$POLICIES_SRC" "$POLICIES_DST"
sudo chmod 644 "$POLICIES_DST"

echo "Done. Restart Mullvad Browser for policies to take effect."
echo ""
echo "Extensions will be auto-installed on all profiles:"
python3 -c "
import json
with open('$POLICIES_SRC') as f:
    data = json.load(f)
for ext_id in data.get('policies', {}).get('ExtensionSettings', {}):
    print(f'  - {ext_id}')
"
