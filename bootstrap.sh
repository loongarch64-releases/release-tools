#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/loongarch64-releases/release-tools.git"
BRANCH="main"

# 1. 创建临时目录
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "📥 Downloading template repository..."
# 浅克隆以加快速度
if ! git clone --depth=1 --branch="$BRANCH" "$REPO_URL" "$TMP_DIR" >/dev/null 2>&1; then
    echo "❌ Failed to clone repository. Is git installed?"
    exit 1
fi

echo "🚀 Starting initialization..."
# 2. 关键：切换到临时目录执行 init.sh，但保持参数传递
# 注意：这里不需要 cd 到目标目录，因为 init.sh 会处理“复制到当前目录”的逻辑
# 用户运行 bootstrap.sh 时，当前目录就是他们想要初始化的目录
chmod +x $TMP_DIR/init.sh
exec "$TMP_DIR/init.sh" "$@"
