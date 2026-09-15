#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
OUTPUT_DIR=${1:-${PROJECT_DIR}/dist}
APP_DIR=${OUTPUT_DIR}/ClickShift.app
CONTENTS_DIR=${APP_DIR}/Contents
MACOS_DIR=${CONTENTS_DIR}/MacOS
RESOURCES_DIR=${CONTENTS_DIR}/Resources
ICONSET_DIR=${PROJECT_DIR}/.build/AppIcon.iconset
APP_VERSION=1.1.0
BUILD_NUMBER=5

cd "${PROJECT_DIR}"
rm -rf "${PROJECT_DIR}/.build/arm64" "${PROJECT_DIR}/.build/x86_64"
swift build -c release --arch arm64 --scratch-path .build/arm64
swift build -c release --arch x86_64 --scratch-path .build/x86_64
ARM64_BIN_DIR=$(swift build -c release --arch arm64 --scratch-path .build/arm64 --show-bin-path)
X86_64_BIN_DIR=$(swift build -c release --arch x86_64 --scratch-path .build/x86_64 --show-bin-path)
lipo -create \
  "${ARM64_BIN_DIR}/ClickShift" \
  "${X86_64_BIN_DIR}/ClickShift" \
  -output ".build/ClickShift-universal"

rm -rf "${APP_DIR}" "${ICONSET_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}" "${ICONSET_DIR}"
cp ".build/ClickShift-universal" "${MACOS_DIR}/ClickShift"
cp "LICENSE" "${RESOURCES_DIR}/LICENSE.txt"
cp "THIRD_PARTY_NOTICES.md" "${RESOURCES_DIR}/THIRD_PARTY_NOTICES.md"
cp "Resources/AppIcon.png" "${RESOURCES_DIR}/AppIcon.png"
sips -z 36 36 "Resources/MenuBarIcon.png" --out "${RESOURCES_DIR}/MenuBarIcon.png" >/dev/null

sips -z 16 16 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_16x16.png" >/dev/null
sips -z 32 32 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_32x32.png" >/dev/null
sips -z 64 64 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_128x128.png" >/dev/null
sips -z 256 256 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_256x256.png" >/dev/null
sips -z 512 512 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_512x512.png" >/dev/null
sips -z 1024 1024 "Resources/AppIcon.png" --out "${ICONSET_DIR}/icon_512x512@2x.png" >/dev/null
iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/AppIcon.icns"

PLIST_PATH=${CONTENTS_DIR}/Info.plist
rm -f "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleDevelopmentRegion string en" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string ClickShift" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string app.clickshift.mac" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleInfoDictionaryVersion string 6.0" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string ClickShift" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string ${APP_VERSION}" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${BUILD_NUMBER}" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 13.0" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :NSBluetoothAlwaysUsageDescription string ClickShift connects to your right Zwift Click v2 controller." "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :NSHumanReadableCopyright string Unofficial open-source utility; not affiliated with Zwift or MyWhoosh." "${PLIST_PATH}"

xattr -cr "${APP_DIR}"
codesign --force --deep --sign - "${APP_DIR}"
echo "Built ${APP_DIR}"
