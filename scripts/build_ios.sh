#!/usr/bin/env bash
# 打 iOS 安装包（release IPA），复制到 dist/<version>/。
# 默认 development 导出，方便本机真机安装；可改 IOS_EXPORT_METHOD=ad-hoc|app-store。
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/_common.sh"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: iOS 打包只能在 macOS 上运行" >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: 找不到 xcodebuild，请先安装 Xcode" >&2
  exit 1
fi

ensure_pub_get

export_method="${IOS_EXPORT_METHOD:-development}"
echo "==> flutter build ipa --release --export-method ${export_method} (${APP_ZH} ${VERSION_NAME})"
flutter build ipa --release --export-method "$export_method"

shopt -s nullglob
ipas=("$ROOT"/build/ios/ipa/*.ipa)
if [[ ${#ipas[@]} -eq 0 ]]; then
  echo "error: 未找到 IPA。请在 Xcode 打开 ios/Runner.xcworkspace，确认 Team=76BA555MU3 且能自动签名。" >&2
  exit 1
fi

dest_ipa="${DIST_DIR}/${APP_ZH}-${VERSION_NAME}-ios.ipa"
cp "${ipas[0]}" "$dest_ipa"

echo "==> 完成"
echo "ipa: $dest_ipa"
