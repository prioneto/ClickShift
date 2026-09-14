#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
OUTPUT_DIR=${1:-${PROJECT_DIR}/dist}
APP_DIR=${OUTPUT_DIR}/ClickShift.app
CONTENTS_DIR=${APP_DIR}/Contents
MACOS_DIR=${CONTENTS_DIR}/MacOS

cd "${PROJECT_DIR}"
swift build -c release

mkdir -p "${MACOS_DIR}"
cp ".build/release/ClickShift" "${MACOS_DIR}/ClickShift"
cp "LICENSE" "${CONTENTS_DIR}/LICENSE.txt"
cp "THIRD_PARTY_NOTICES.md" "${CONTENTS_DIR}/THIRD_PARTY_NOTICES.md"

PLIST_PATH=${CONTENTS_DIR}/Info.plist
rm -f "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleDevelopmentRegion string en" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string ClickShift" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string app.clickshift.mac" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleInfoDictionaryVersion string 6.0" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string ClickShift" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0.0" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 13.0" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :NSBluetoothAlwaysUsageDescription string ClickShift connects to your right Zwift Click v2 controller." "${PLIST_PATH}"
/usr/libexec/PlistBuddy -c "Add :NSHumanReadableCopyright string Unofficial open-source utility; not affiliated with Zwift or MyWhoosh." "${PLIST_PATH}"

xattr -cr "${APP_DIR}"
codesign --force --deep --sign - "${APP_DIR}"
echo "Built ${APP_DIR}"
