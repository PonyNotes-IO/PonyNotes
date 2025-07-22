#!/bin/bash

# 🚀 小马笔记 - 完整功能快速构建脚本
# 保留所有原始功能，优化构建速度

set -e

# 颜色定义
RED='\033[0;31m'
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

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🚀 小马笔记 - 完整功能快速构建"
echo "================================"

# 记录开始时间
START_TIME=$(date +%s)

# 1. 设置构建优化环境
print_info "设置构建优化环境..."
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export RUSTC_WRAPPER=sccache
export CARGO_INCREMENTAL=1
export CARGO_BUILD_JOBS=$(sysctl -n hw.ncpu)

# 设置 Rust 优化
export RUSTFLAGS="-C target-cpu=native -C opt-level=2"
export CARGO_TARGET_DIR=~/.cargo-target-cache

# 2. 进入 Flutter 项目目录
cd frontend/appflowy_flutter

# 3. 清理并获取依赖
print_info "清理旧的构建产物..."
flutter clean > /dev/null 2>&1

print_info "获取 Flutter 依赖..."
flutter pub get

# 4. 预编译 Rust 依赖 (并行)
print_info "预编译 Rust 后端 (并行处理)..."
cd ../rust-lib

# 使用 cargo 并行编译
if command -v cargo &> /dev/null; then
    print_info "编译 Rust 库..."
    cargo build --release --jobs $(sysctl -n hw.ncpu) &
    RUST_PID=$!
else
    print_warning "Cargo 未找到，跳过 Rust 预编译"
    RUST_PID=""
fi

# 回到 Flutter 目录
cd ../appflowy_flutter

# 5. 优化 Flutter 构建配置
print_info "优化 Flutter 构建配置..."

# 创建优化的构建配置
cat > macos/Flutter/Release.xcconfig << 'EOF'
#include "ephemeral/Flutter-Generated.xcconfig"
FLUTTER_BUILD_MODE=release
FLUTTER_BUILD_NAME=0.9.4
FLUTTER_BUILD_NUMBER=1
DART_OBFUSCATION=false
TRACK_WIDGET_CREATION=false
TREE_SHAKE_ICONS=true
PACKAGE_CONFIG=.dart_tool/package_config.json
COMPILER_INDEX_STORE_ENABLE=NO
SWIFT_COMPILATION_MODE=wholemodule
SWIFT_OPTIMIZATION_LEVEL=-O
GCC_OPTIMIZATION_LEVEL=fast
ENABLE_BITCODE=NO
EOF

# 6. 优化 Xcode 项目设置
print_info "优化 Xcode 项目设置..."
if [ -f "macos/Runner.xcodeproj/project.pbxproj" ]; then
    # 备份原始文件
    cp macos/Runner.xcodeproj/project.pbxproj macos/Runner.xcodeproj/project.pbxproj.backup
    
    # 优化编译设置
    sed -i.tmp 's/COMPILER_INDEX_STORE_ENABLE = YES/COMPILER_INDEX_STORE_ENABLE = NO/g' macos/Runner.xcodeproj/project.pbxproj
    sed -i.tmp 's/SWIFT_COMPILATION_MODE = singlefile/SWIFT_COMPILATION_MODE = wholemodule/g' macos/Runner.xcodeproj/project.pbxproj
    
    rm -f macos/Runner.xcodeproj/project.pbxproj.tmp
fi

# 7. 等待 Rust 编译完成
if [ ! -z "$RUST_PID" ]; then
    print_info "等待 Rust 编译完成..."
    wait $RUST_PID
    if [ $? -eq 0 ]; then
        print_success "Rust 编译完成"
    else
        print_warning "Rust 编译失败，继续 Flutter 构建"
    fi
fi

# 8. 执行优化的 Flutter 构建
print_info "执行完整功能构建..."

# 尝试不同的构建策略
BUILD_SUCCESS=false

# 策略1: Release 构建 (最快)
print_info "尝试 Release 构建..."
if flutter build macos --release --no-tree-shake-icons --dart-define=FLUTTER_WEB_USE_SKIA=true; then
    BUILD_SUCCESS=true
    BUILD_TYPE="Release"
    print_success "Release 构建成功！"
else
    print_warning "Release 构建失败，尝试 Debug 构建..."
    
    # 策略2: Debug 构建 (更兼容)
    if flutter build macos --debug --no-tree-shake-icons; then
        BUILD_SUCCESS=true
        BUILD_TYPE="Debug"
        print_success "Debug 构建成功！"
    else
        print_warning "Debug 构建失败，尝试 Profile 构建..."
        
        # 策略3: Profile 构建 (平衡)
        if flutter build macos --profile --no-tree-shake-icons; then
            BUILD_SUCCESS=true
            BUILD_TYPE="Profile"
            print_success "Profile 构建成功！"
        else
            print_error "所有构建策略都失败了"
            
            # 恢复原始配置
            if [ -f "macos/Runner.xcodeproj/project.pbxproj.backup" ]; then
                mv macos/Runner.xcodeproj/project.pbxproj.backup macos/Runner.xcodeproj/project.pbxproj
            fi
            
            exit 1
        fi
    fi
fi

# 9. 构建后处理
if [ "$BUILD_SUCCESS" = true ]; then
    # 计算构建时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    print_success "完整功能构建完成！"
    print_info "构建类型: $BUILD_TYPE"
    print_info "构建时间: ${MINUTES}分${SECONDS}秒"
    
    # 显示应用信息
    APP_PATH="build/macos/Build/Products/$BUILD_TYPE/AppFlowy.app"
    if [ -d "$APP_PATH" ]; then
        APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
        print_info "应用大小: $APP_SIZE"
        print_info "应用位置: frontend/appflowy_flutter/$APP_PATH"
        
        # 验证应用完整性
        print_info "验证应用完整性..."
        if [ -f "$APP_PATH/Contents/MacOS/AppFlowy" ]; then
            print_success "应用可执行文件存在"
        else
            print_warning "应用可执行文件缺失"
        fi
        
        if [ -d "$APP_PATH/Contents/Frameworks" ]; then
            FRAMEWORK_COUNT=$(ls -1 "$APP_PATH/Contents/Frameworks" | wc -l)
            print_info "包含框架数量: $FRAMEWORK_COUNT"
        fi
        
        # 提供启动命令
        echo ""
        print_success "🎉 构建完成！启动应用："
        echo "open frontend/appflowy_flutter/$APP_PATH"
        echo ""
        print_info "或者双击应用图标启动"
        
    else
        print_error "应用文件未找到: $APP_PATH"
    fi
    
    # 恢复原始配置
    if [ -f "macos/Runner.xcodeproj/project.pbxproj.backup" ]; then
        mv macos/Runner.xcodeproj/project.pbxproj.backup macos/Runner.xcodeproj/project.pbxproj
        print_info "已恢复原始 Xcode 配置"
    fi
    
    # 显示缓存统计
    if command -v sccache &> /dev/null; then
        echo ""
        print_info "Rust 编译缓存统计:"
        sccache --show-stats
    fi
    
else
    print_error "构建失败"
    exit 1
fi 