#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# 配置
# ==========================================
DEFAULT_TARGET_ORG="loongarch64-releases"
TEMPLATE_DIR_NAME="templates" # 模板文件夹名字

# ==========================================
# 辅助函数
# ==========================================
log_info() { echo -e "\033[0;32m[INFO]\033[0m $*"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; exit 1; }

# ==========================================
# 1. 定位脚本自身所在目录 (Source of Truth)
# ==========================================
# 无论脚本是被 curl piped (此时 $0 是 -bash 或 sh，需特殊处理，但在本方案中是通过 exec 调用的，所以 $0 有效)
# 还是本地直接运行，以下逻辑都能找到脚本所在的绝对路径
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 构造模板源的绝对路径
TEMPLATE_SOURCE="${SCRIPT_PATH}/${TEMPLATE_DIR_NAME}"

if [ ! -d "$TEMPLATE_SOURCE" ]; then
    log_error "Cannot find templates directory at: ${TEMPLATE_SOURCE}"
    log_error "Make sure init.sh and the templates/ folder are in the same parent directory."
fi

# ==========================================
# 2. 解析参数
# ==========================================
if [ $# -lt 2 ]; then
    cat <<EOF
Usage: 
  Local:  /path/to/init.sh <UPSTREAM_OWNER> <UPSTREAM_REPO> [TARGET_ORG]
  Remote: curl ... | bash -s -- <UPSTREAM_OWNER> <UPSTREAM_REPO> [TARGET_ORG]

Arguments:
  UPSTREAM_OWNER   : The owner of the source repo (e.g., langgenius)
  UPSTREAM_REPO    : The name of the source repo (e.g., dify-sandbox)
  TARGET_ORG       : Your organization name (default: ${DEFAULT_TARGET_ORG})
EOF
    exit 1
fi

UPSTREAM_OWNER="$1"
UPSTREAM_REPO="$2"
TARGET_ORG="${3:-$DEFAULT_TARGET_ORG}"

# ==========================================
# 3. 执行初始化 (在当前工作目录)
# ==========================================
TARGET_DIR="$(pwd)"

log_info "🎯 Target directory: ${TARGET_DIR}"
log_info "📂 Source templates: ${TEMPLATE_SOURCE}"
log_info "⚙️  Variables: OWNER=${UPSTREAM_OWNER}, REPO=${UPSTREAM_REPO}, ORG=${TARGET_ORG}"

# 检查目标目录是否为空 (可选的安全检查，防止误覆盖)
if [ "$(ls -A .)" ]; then
    echo -n "⚠️  Current directory is not empty. Continue? [y/N] "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_error "Aborted by user."
    fi
fi

log_info "📦 Copying files..."
# 复制模板内容到当前目录
# 注意：cp -a 保留权限，src/. 表示复制目录下的所有内容
cp -a "${TEMPLATE_SOURCE}/." .

log_info "🔄 Replacing variables..."
# 先替换 TITLE，首字母大写
TEMP_NAME="${UPSTREAM_REPO//-/ }"
TITLE_NAME=$(echo "$TEMP_NAME" | awk 'BEGIN{FS=OFS=" "} {for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
sed -i "s|{{TITLE_NAME}}|${TITLE_NAME}|g" README.md

# 递归替换变量
# 只处理文本类文件，避免损坏二进制文件
find . -type f \( \
    -name "*.sh" -o \
    -name "*.yml" -o \
    -name "*.yaml" -o \
    -name "*.md" -o \
    -name "*.txt" -o \
    -name "*.json" -o \
    -name "*.toml" -o \
    -name "Dockerfile*" \
\) | while read -r file; do
    # 跳过 .git 目录 (如果不小心复制了的话)
    [[ "$file" == *"/.git/"* ]] && continue
    
    # 区分 GNU sed (Linux) 和 BSD sed (macOS)
    if sed --version >/dev/null 2>&1; then
        # Linux
        sed -i \
            -e "s/{{UPSTREAM_OWNER}}/${UPSTREAM_OWNER}/g" \
            -e "s/{{UPSTREAM_REPO}}/${UPSTREAM_REPO}/g" \
            -e "s/{{TARGET_ORG}}/${TARGET_ORG}/g" \
            "$file"
    else
        # macOS
        sed -i '' \
            -e "s/{{UPSTREAM_OWNER}}/${UPSTREAM_OWNER}/g" \
            -e "s/{{UPSTREAM_REPO}}/${UPSTREAM_REPO}/g" \
            -e "s/{{TARGET_ORG}}/${TARGET_ORG}/g" \
            "$file"
    fi
done

# ==========================================
# 4. 清理与收尾
# ==========================================
# 如果模板里包含了 init.sh 或 bootstrap.sh 本身，且你不希望它们出现在用户项目中，可以在这里删除
# rm -f ./init.sh ./bootstrap.sh 

log_info "✅ Initialization successful!"
echo ""
echo "📁 Files generated:"
ls -la
echo ""
echo "Next steps:"
echo "  1. Review the files."
echo "  2. git init && git add . && git commit -m 'chore: init project'"
