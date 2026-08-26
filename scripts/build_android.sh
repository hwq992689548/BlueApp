#!/usr/bin/env bash
# 打 Android 安装包（release APK），复制到 dist/<version>/。
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/_common.sh"

if [[ ! -f "$ROOT/scripts/lanbao-release.jks" || ! -f "$ROOT/scripts/key.properties" ]]; then
  echo "error: 缺少 Android 签名文件 scripts/lanbao-release.jks 或 scripts/key.properties" >&2
  exit 1
fi

ensure_pub_get

echo "==> flutter build apk --release (${APP_ZH} ${VERSION_NAME})"
flutter build apk --release

src_apk="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$src_apk" ]]; then
  echo "error: 未找到 APK: $src_apk" >&2
  exit 1
fi

dest_apk="${DIST_DIR}/${APP_ZH}-${VERSION_NAME}-android.apk"
cp "$src_apk" "$dest_apk"

echo "==> 完成"
echo "apk: $dest_apk"
