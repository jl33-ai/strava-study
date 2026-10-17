#!/bin/bash
set -euo pipefail
# Archive, export, validate and upload a build to App Store Connect (TestFlight).
#
#   ./ship.sh            archive and upload
#   ./ship.sh --archive  archive only (checks that it signs)
#
# Ships into the Lockin record (io.getden.lockin) on team WR8US6FK26 with the App Store Connect API
# key at ~/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8. Every upload needs a higher
# CURRENT_PROJECT_VERSION (project.yml) than the last.
cd "$(dirname "$0")"
ARCHIVE_ONLY=0
[[ "${1:-}" == "--archive" ]] && ARCHIVE_ONLY=1
: "${ASC_KEY_ID:=DXV37QNTAG}"
: "${ASC_ISSUER_ID:=39f73c3a-9bea-4924-9791-889584a7d5aa}"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_$ASC_KEY_ID.p8"
[[ -f "$KEY_PATH" ]] || { echo "No API key at $KEY_PATH" >&2; exit 1; }
ARCHIVE="$PWD/build/Lockin.xcarchive"
EXPORT="$PWD/build/export"
AUTH=(-allowProvisioningUpdates -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID" -authenticationKeyPath "$KEY_PATH")

xcodegen generate
rm -rf "$ARCHIVE"
xcodebuild archive -project Lockin.xcodeproj -scheme Lockin -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" "${AUTH[@]}"
PLIST="$ARCHIVE/Products/Applications/Lockin.app/Info.plist"
plist() { /usr/libexec/PlistBuddy -c "Print $1" "$PLIST" 2>/dev/null; }
echo "version $(plist CFBundleShortVersionString) build $(plist CFBundleVersion) bundle $(plist CFBundleIdentifier)"
[[ "$ARCHIVE_ONLY" == 1 ]] && { echo "Archived at $ARCHIVE"; exit 0; }

rm -rf "$EXPORT"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist ExportOptions.plist -exportPath "$EXPORT" "${AUTH[@]}"
IPA="$EXPORT/Lockin.ipa"
xcrun altool --validate-app -f "$IPA" -t ios --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
xcrun altool --upload-app -f "$IPA" -t ios --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
echo "Uploaded; it shows in App Store Connect once processed (5-30 minutes)."
