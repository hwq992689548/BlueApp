# 蓝宝助手 / BlueStack 打包公共变量。由 build_*.sh source。
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_ZH="蓝宝助手"
APP_EN="BlueStack"

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: 找不到 flutter，请先加入 PATH" >&2
  exit 1
fi

version_line="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
VERSION_NAME="${version_line%%+*}"
if [[ -z "$VERSION_NAME" ]]; then
  echo "error: 无法从 pubspec.yaml 解析 version" >&2
  exit 1
fi

DIST_DIR="$ROOT/dist/${VERSION_NAME}"
mkdir -p "$DIST_DIR"

ensure_pub_get() {
  echo "==> flutter pub get"
  flutter pub get
}
