#!/bin/bash

# 🔧 小马笔记 - 构建环境设置脚本
# 解决网络问题和依赖配置

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🔧 设置小马笔记构建环境"
echo "=========================="

# 1. 配置 Flutter 国内镜像
print_info "配置 Flutter 国内镜像..."
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 写入到 shell 配置文件
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.profile"
fi

# 检查是否已经配置
if ! grep -q "PUB_HOSTED_URL" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Flutter 国内镜像配置" >> "$SHELL_RC"
    echo "export PUB_HOSTED_URL=https://pub.flutter-io.cn" >> "$SHELL_RC"
    echo "export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn" >> "$SHELL_RC"
    print_success "Flutter 镜像配置已添加到 $SHELL_RC"
else
    print_info "Flutter 镜像配置已存在"
fi

# 2. 安装 sccache (Rust 编译缓存)
print_info "检查 sccache..."
if ! command -v sccache &> /dev/null; then
    print_info "安装 sccache..."
    if command -v brew &> /dev/null; then
        brew install sccache
    else
        print_warning "请手动安装 Homebrew 后再运行此脚本"
        print_info "安装命令: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
else
    print_success "sccache 已安装"
fi

# 3. 配置 Rust 编译优化
print_info "配置 Rust 编译优化..."
if ! grep -q "RUSTC_WRAPPER" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Rust 编译优化配置" >> "$SHELL_RC"
    echo "export RUSTC_WRAPPER=sccache" >> "$SHELL_RC"
    echo "export CARGO_INCREMENTAL=1" >> "$SHELL_RC"
    echo "export CARGO_BUILD_JOBS=\$(sysctl -n hw.ncpu)" >> "$SHELL_RC"
    print_success "Rust 编译优化配置已添加"
else
    print_info "Rust 编译优化配置已存在"
fi

# 4. 创建 Cargo 配置文件
print_info "配置 Cargo 国内镜像..."
CARGO_CONFIG_DIR="$HOME/.cargo"
CARGO_CONFIG_FILE="$CARGO_CONFIG_DIR/config.toml"

mkdir -p "$CARGO_CONFIG_DIR"

if [ ! -f "$CARGO_CONFIG_FILE" ]; then
    cat > "$CARGO_CONFIG_FILE" << 'EOF'
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'ustc'

[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

[net]
git-fetch-with-cli = true

[build]
jobs = 8
EOF
    print_success "Cargo 配置文件已创建"
else
    print_info "Cargo 配置文件已存在"
fi

# 5. 优化系统设置
print_info "优化系统设置..."
# 增加文件描述符限制
if ! grep -q "ulimit -n 65536" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# 系统优化配置" >> "$SHELL_RC"
    echo "ulimit -n 65536" >> "$SHELL_RC"
    print_success "文件描述符限制已配置"
fi

# 6. 创建构建缓存目录
print_info "创建构建缓存目录..."
mkdir -p "$HOME/.cargo-target-cache"
mkdir -p "$HOME/.flutter-build-cache"

# 7. 验证配置
print_info "验证配置..."
source "$SHELL_RC" 2>/dev/null || true

echo ""
print_success "构建环境设置完成！"
echo ""
print_info "配置摘要:"
echo "  ✓ Flutter 国内镜像已配置"
echo "  ✓ Rust 编译缓存已配置"
echo "  ✓ Cargo 国内镜像已配置"
echo "  ✓ 系统优化已配置"
echo "  ✓ 构建缓存目录已创建"
echo ""
print_warning "请重新启动终端或运行 'source $SHELL_RC' 使配置生效"
echo ""
print_info "现在可以使用快速构建脚本:"
echo "  ./scripts/quick_build.sh dev      # 开发模式"
echo "  ./scripts/quick_build.sh debug    # 调试构建"
echo "  ./scripts/quick_build.sh release  # 发布构建" 