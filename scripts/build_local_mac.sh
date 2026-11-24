#!/bin/bash
# 在 macOS 本地编译（没走 GitHub Actions 时用），需先装 Xcode + xcodegen
#   brew install xcodegen
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate

xcodebuild archive \
  -project YouyouguH5.xcodeproj \
  -scheme YouyouguH5 \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath build/YouyouguH5.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

rm -rf build/Payload
mkdir -p build/Payload
cp -R build/YouyouguH5.xcarchive/Products/Applications/YouyouguH5.app build/Payload/
( cd build && zip -qry YouyouguH5-1.0.0-unsigned.ipa Payload )

echo "已生成 build/YouyouguH5-1.0.0-unsigned.ipa"
