#!/usr/bin/env bash
set -euo pipefail

MANIFEST_FILE="net.imput.helium.yml"
METADATA_FILE="net.imput.helium.metainfo.xml"
REPO_URL="https://github.com/imputnet/helium-linux/releases/download"

if [ -f "fetch.config.yml" ]; then
    ALLOW_PRERELEASE=$(grep -m1 'allow-prerelease:' fetch.config.yml | awk '{print $2}')
else
    ALLOW_PRERELEASE="false"
fi

echo "   Fetching releases from GitHub..."
RELEASES_JSON=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases)

read -r LATEST_VERSION LATEST_RELEASE_DATE IS_PRERELEASE <<< $(echo "$RELEASES_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    allow_pre = '${ALLOW_PRERELEASE}' == 'true'
    if not isinstance(data, list):
        print('null null false')
        sys.exit(0)
    candidates = [r for r in data if r.get('tag_name') and (allow_pre or not r.get('prerelease', False))]
    if candidates:
        latest = sorted(candidates, key=lambda x: x.get('created_at', ''))[-1]
        # Extract just the date part from published_at (e.g., '2026-02-24T10:30:00Z' -> '2026-02-24')
        release_date = latest.get('published_at', '')[:10]
        print(f\"{latest['tag_name']} {release_date} {str(latest['prerelease']).lower()}\")
    else:
        print('null null false')
except Exception:
    print('null null false')
")

if [[ -z "$LATEST_VERSION" || "$LATEST_VERSION" == "null" ]]; then
  echo "   Error: Failed to fetch valid version tag from GitHub."
  exit 1
fi

CURRENT_VERSION=$(grep -Po 'helium-[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?' "$MANIFEST_FILE" | head -n1 | grep -Po '[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?')
CURRENT_DATE=$(grep -Po '(?<=date=")[0-9]{4}-[0-9]{2}-[0-9]{2}' "$METADATA_FILE" | head -n1)

echo "version: $CURRENT_VERSION" > version.txt
echo "prerelease: $IS_PRERELEASE" >> version.txt

# Check if both version and date are up to date
VERSION_UP_TO_DATE=false
DATE_UP_TO_DATE=false

if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
  VERSION_UP_TO_DATE=true
  echo "   Version is up to date ($CURRENT_VERSION)."
else
  echo "   Updating manifest from $CURRENT_VERSION → $LATEST_VERSION"
fi

if [[ "$CURRENT_DATE" == "$LATEST_RELEASE_DATE" ]]; then
  DATE_UP_TO_DATE=true
  echo "   Date is up to date ($CURRENT_DATE)."
else
  echo "   Updating date from $CURRENT_DATE → $LATEST_RELEASE_DATE"
fi

# Exit early only if both version and date are current
if [[ "$VERSION_UP_TO_DATE" == true && "$DATE_UP_TO_DATE" == true ]]; then
  echo "   Manifest is already fully up to date."
  exit 0
fi

if [[ "$OSTYPE" == "darwin"* ]]; then SED_INPLACE="sed -i ''"; else SED_INPLACE="sed -i"; fi

# --- Update version in files if needed ---
if [[ "$VERSION_UP_TO_DATE" == false ]]; then
  $SED_INPLACE -E "s|(helium-linux/releases/download/)$CURRENT_VERSION|\1$LATEST_VERSION|g" "$MANIFEST_FILE"
  $SED_INPLACE -E "s|(helium-$CURRENT_VERSION-x86_64_linux)|helium-$LATEST_VERSION-x86_64_linux|g" "$MANIFEST_FILE"
  $SED_INPLACE -E "s|(helium-$CURRENT_VERSION-arm64_linux)|helium-$LATEST_VERSION-arm64_linux|g" "$MANIFEST_FILE"
  $SED_INPLACE -E "s|(<release version=['\"])$CURRENT_VERSION|\1$LATEST_VERSION|g" "$METADATA_FILE"

  # Update the version tracker
  echo "version: $LATEST_VERSION" > version.txt
  echo "prerelease: $IS_PRERELEASE" >> version.txt
fi

# --- Always update date if needed ---
if [[ "$DATE_UP_TO_DATE" == false ]]; then
  $SED_INPLACE -E "s|(<release date=['\"])[0-9]{4}-[0-9]{2}-[0-9]{2}|\1$LATEST_RELEASE_DATE|g" "$METADATA_FILE"
fi

echo "   Downloading binaries to compute SHA256..."

DL_X86="$REPO_URL/$LATEST_VERSION/helium-$LATEST_VERSION-x86_64_linux.tar.xz"
TMP_X86=$(mktemp)
curl -L -s -o "$TMP_X86" "$DL_X86"
NEW_SHA256_X86=$(sha256sum "$TMP_X86" | awk '{print $1}')
rm -f "$TMP_X86"

DL_ARM="$REPO_URL/$LATEST_VERSION/helium-$LATEST_VERSION-arm64_linux.tar.xz"
TMP_ARM=$(mktemp)
curl -L -s -o "$TMP_ARM" "$DL_ARM"
NEW_SHA256_ARM=$(sha256sum "$TMP_ARM" | awk '{print $1}')
rm -f "$TMP_ARM"

if [[ -z "$NEW_SHA256_X86" || -z "$NEW_SHA256_ARM" ]]; then
  echo "   Failed to compute SHA256 checksums."
  exit 1
fi

echo "   New x86_64 SHA256: $NEW_SHA256_X86"
echo "   New aarch64 SHA256: $NEW_SHA256_ARM"

# This finds the URL line for each architecture, moves to the next line (n), and replaces the hash.
$SED_INPLACE -E "/x86_64_linux\.tar\.xz/{n;s/sha256: [a-f0-9]+/sha256: $NEW_SHA256_X86/;}" "$MANIFEST_FILE"
$SED_INPLACE -E "/arm64_linux\.tar\.xz/{n;s/sha256: [a-f0-9]+/sha256: $NEW_SHA256_ARM/;}" "$MANIFEST_FILE"

echo "   Manifest updated successfully."
