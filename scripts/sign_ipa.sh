#!/bin/bash
# 用企业证书给未签名 IPA 重签（在 macOS 上跑）
# 用法：
#   ./scripts/sign_ipa.sh <未签名.ipa> "<证书名>" <mobileprovision路径> [entitlements路径]
# 例：
#   ./scripts/sign_ipa.sh YouyouguH5-1.0.0-unsigned.ipa "iPhone Distribution: 游游谷网络科技有限公司" ./enterprise.mobileprovision
#
# 查证书名：security find-identity -v -p codesigning

set -euo pipefail

IPA="${1:?需要未签名 ipa}"
IDENTITY="${2:?需要证书名}"
PROFILE="${3:?需要 mobileprovision}"
ENTITLE="${4:-}"

WORK="$(mktemp -d)"
unzip -oq "$IPA" -d "$WORK"
APP="$WORK/Payload/YouyouguH5.app"

if [ ! -d "$APP" ]; then
  echo "包里没找到 YouyouguH5.app，检查 PRODUCT_NAME 是否被改过"; exit 1
fi

cp "$PROFILE" "$APP/embedded.mobileprovision"

if [ -n "$ENTITLE" ]; then
  codesign -f -s "$IDENTITY" --entitlements "$ENTITLE" --timestamp=none "$APP"
else
  codesign -f -s "$IDENTITY" --timestamp=none "$APP"
fi

OUT="${IPA%.ipa}-signed.ipa"
( cd "$WORK" && zip -qry "$OUT" Payload )
mv "$WORK/$OUT" "./$OUT"
rm -rf "$WORK"

echo "签名完成：$OUT"
echo "校验：codesign -dv --verbose=4 Payload/YouyouguH5.app"
