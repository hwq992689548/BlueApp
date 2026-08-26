#!/usr/bin/env bash
# 一次打 Android APK + iOS IPA（顺序执行，避免抢同一份 Flutter build 目录）。
set -euo pipefail

scripts_dir="$(cd "$(dirname "$0")" && pwd)"

echo "==> 开始打包 Android + iOS"
"$scripts_dir/build_android.sh"
"$scripts_dir/build_ios.sh"
echo "==> 两个包都打完了"
