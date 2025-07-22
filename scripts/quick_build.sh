#!/bin/bash

# 🚀 小马笔记 - 快速构建脚本
# 使用方法: ./scripts/quick_build.sh [模式]
# 模式: dev, debug, release, clean

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查依赖
check_dependencies() {
    print_info "检查构建依赖..."
    
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter 未安装或不在 PATH 中"
        exit 1
    fi
    
    if ! command -v cargo &> /dev/null; then
        print_error "Rust/Cargo 未安装"
        exit 1
    fi
    
    print_success "依赖检查完成"
}

# 设置构建优化环境变量
setup_build_env() {
    print_info "设置构建环境..."
    
    # Rust 编译优化
    export RUSTC_WRAPPER=sccache
    export CARGO_INCREMENTAL=1
    export CARGO_BUILD_JOBS=$(sysctl -n hw.ncpu)
    
    # Flutter 优化
    export PUB_HOSTED_URL=https://pub.flutter-io.cn
    export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
    
    # 系统优化
    ulimit -n 65536
    
    print_success "环境配置完成"
}

# 开发模式 - 热重载
dev_mode() {
    print_info "启动开发模式 (热重载)..."
    print_warning "这将启动应用并支持热重载，按 Ctrl+C 退出"
    
    cd frontend/appflowy_flutter
    flutter run -d macos --hot
}

# 调试构建
debug_build() {
    print_info "开始调试构建..."
    
    cd frontend/appflowy_flutter
    
    # 获取依赖
    print_info "获取 Flutter 依赖..."
    flutter pub get
    
    # 调试构建
    print_info "执行调试构建..."
    flutter build macos --debug
    
    print_success "调试构建完成！"
    print_info "应用位置: build/macos/Build/Products/Debug/AppFlowy.app"
}

# 发布构建
release_build() {
    print_info "开始发布构建..."
    
    cd frontend/appflowy_flutter
    
    # 获取依赖
    print_info "获取 Flutter 依赖..."
    flutter pub get
    
    # 发布构建
    print_info "执行发布构建..."
    flutter build macos --release
    
    print_success "发布构建完成！"
    print_info "应用位置: build/macos/Build/Products/Release/AppFlowy.app"
}

# 清理构建
clean_build() {
    print_info "清理构建缓存..."
    
    cd frontend/appflowy_flutter
    
    # Flutter 清理
    flutter clean
    
    # 删除构建目录
    rm -rf build/
    rm -rf macos/Pods/
    
    # 清理 Rust 缓存
    if [ -d "../rust-lib" ]; then
        cd ../rust-lib
        cargo clean
        cd ../appflowy_flutter
    fi
    
    print_success "清理完成！"
}

# 显示帮助信息
show_help() {
    echo "🚀 小马笔记 - 快速构建脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [模式]"
    echo ""
    echo "可用模式:"
    echo "  dev     - 开发模式 (热重载) - 最快"
    echo "  debug   - 调试构建 - 快速测试"
    echo "  release - 发布构建 - 生产版本"
    echo "  clean   - 清理构建缓存"
    echo ""
    echo "示例:"
    echo "  $0 dev      # 启动开发模式"
    echo "  $0 debug    # 快速调试构建"
    echo "  $0 release  # 完整发布构建"
    echo "  $0 clean    # 清理缓存"
}

# 显示构建时间估算
show_time_estimate() {
    case $1 in
        "dev")
            print_info "预计时间: 5-8分钟 (首次启动)"
            ;;
        "debug")
            print_info "预计时间: 3-5分钟 (增量构建)"
            ;;
        "release")
            print_info "预计时间: 10-15分钟 (完整构建)"
            ;;
        "clean")
            print_info "预计时间: 1-2分钟"
            ;;
    esac
}

# 主函数
main() {
    echo "🚀 小马笔记 - 快速构建脚本"
    echo "================================"
    
    # 检查参数
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi
    
    MODE=$1
    
    # 显示时间估算
    show_time_estimate $MODE
    
    # 检查依赖
    check_dependencies
    
    # 设置环境
    setup_build_env
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 根据模式执行相应操作
    case $MODE in
        "dev")
            dev_mode
            ;;
        "debug")
            debug_build
            ;;
        "release")
            release_build
            ;;
        "clean")
            clean_build
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "未知模式: $MODE"
            show_help
            exit 1
            ;;
    esac
    
    # 计算并显示构建时间
    if [ "$MODE" != "dev" ] && [ "$MODE" != "help" ]; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        MINUTES=$((DURATION / 60))
        SECONDS=$((DURATION % 60))
        
        print_success "构建完成！用时: ${MINUTES}分${SECONDS}秒"
    fi
}

# 执行主函数
main "$@" 