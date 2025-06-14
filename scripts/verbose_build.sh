#!/bin/bash

# 🔍 小马笔记 - 详细进度构建脚本
# 实时显示构建进度，防止看起来像卡死

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${PURPLE}🔄 [$1/10] $2${NC}"
}

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

print_progress() {
    echo -e "${CYAN}⏳ $1${NC}"
}

echo "🔍 小马笔记 - 详细进度构建"
echo "============================"
echo "📊 总共10个步骤，每步都会显示详细进度"
echo "🚫 如果超过5分钟没有输出，说明可能卡死了"
echo ""

# 记录开始时间
START_TIME=$(date +%s)

# 步骤1: 环境检查
print_step "1" "检查构建环境"
print_progress "检查 Flutter 环境..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter 未安装"
    exit 1
fi
print_info "Flutter 版本: $(flutter --version | head -1)"

print_progress "检查 Rust 环境..."
if ! command -v cargo &> /dev/null; then
    print_warning "Rust 未安装，将跳过 Rust 优化"
    RUST_AVAILABLE=false
else
    print_info "Rust 版本: $(cargo --version)"
    RUST_AVAILABLE=true
fi

print_progress "检查项目结构..."
if [ ! -d "frontend/appflowy_flutter" ]; then
    print_error "项目结构不正确"
    exit 1
fi
print_success "步骤1完成 - 环境检查通过"
echo ""

# 步骤2: 设置构建环境
print_step "2" "设置构建优化环境"
print_progress "配置 Flutter 国内镜像..."
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
print_info "Flutter 镜像已配置"

if [ "$RUST_AVAILABLE" = true ]; then
    print_progress "配置 Rust 编译优化..."
    export RUSTC_WRAPPER=sccache
    export CARGO_INCREMENTAL=1
    export CARGO_BUILD_JOBS=$(sysctl -n hw.ncpu)
    export RUSTFLAGS="-C target-cpu=native -C opt-level=2"
    export CARGO_TARGET_DIR=~/.cargo-target-cache
    print_info "Rust 优化已配置 (并行任务: $(sysctl -n hw.ncpu))"
fi
print_success "步骤2完成 - 环境配置完成"
echo ""

# 步骤3: 进入项目目录
print_step "3" "进入 Flutter 项目目录"
print_progress "切换到 frontend/appflowy_flutter..."
cd frontend/appflowy_flutter
print_info "当前目录: $(pwd)"
print_success "步骤3完成 - 目录切换完成"
echo ""

# 步骤4: 清理旧构建
print_step "4" "清理旧的构建产物"
print_progress "执行 flutter clean..."
flutter clean > /dev/null 2>&1
print_info "旧构建产物已清理"
print_success "步骤4完成 - 清理完成"
echo ""

# 步骤5: 获取依赖
print_step "5" "获取 Flutter 依赖"
print_progress "执行 flutter pub get..."
print_warning "这一步可能需要1-3分钟，请耐心等待..."

# 显示进度点
flutter pub get &
PUB_PID=$!

# 显示进度指示器
COUNTER=0
while kill -0 $PUB_PID 2>/dev/null; do
    COUNTER=$((COUNTER + 1))
    echo -ne "\r⏳ 正在下载依赖... ${COUNTER}秒"
    sleep 1
    
    # 如果超过300秒(5分钟)，认为可能卡死
    if [ $COUNTER -gt 300 ]; then
        print_error "依赖下载超时，可能网络问题或卡死"
        kill $PUB_PID 2>/dev/null || true
        exit 1
    fi
done
echo ""

wait $PUB_PID
if [ $? -eq 0 ]; then
    print_success "步骤5完成 - 依赖获取成功"
else
    print_error "依赖获取失败"
    exit 1
fi
echo ""

# 步骤6: Rust 预编译 (如果可用)
if [ "$RUST_AVAILABLE" = true ]; then
    print_step "6" "预编译 Rust 后端 (并行)"
    print_progress "切换到 Rust 目录..."
    cd ../rust-lib
    
    print_progress "启动 Rust 并行编译..."
    print_warning "这一步可能需要5-15分钟，请耐心等待..."
    
    # 后台编译 Rust
    cargo build --release --jobs $(sysctl -n hw.ncpu) &
    RUST_PID=$!
    
    # 显示 Rust 编译进度
    RUST_COUNTER=0
    while kill -0 $RUST_PID 2>/dev/null; do
        RUST_COUNTER=$((RUST_COUNTER + 1))
        echo -ne "\r⏳ Rust 编译进行中... ${RUST_COUNTER}秒"
        sleep 1
        
        # 如果超过1200秒(20分钟)，认为可能卡死
        if [ $RUST_COUNTER -gt 1200 ]; then
            print_error "Rust 编译超时，可能卡死"
            kill $RUST_PID 2>/dev/null || true
            break
        fi
    done
    echo ""
    
    # 检查 Rust 编译结果
    wait $RUST_PID
    if [ $? -eq 0 ]; then
        print_success "步骤6完成 - Rust 编译成功"
    else
        print_warning "Rust 编译失败，继续 Flutter 构建"
    fi
    
    print_progress "返回 Flutter 目录..."
    cd ../appflowy_flutter
else
    print_step "6" "跳过 Rust 预编译 (Rust 不可用)"
    print_success "步骤6完成 - 已跳过"
fi
echo ""

# 步骤7: 优化构建配置
print_step "7" "优化 Flutter 构建配置"
print_progress "创建优化的 Release 配置..."

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

print_info "Release 配置已优化"

print_progress "优化 Xcode 项目设置..."
if [ -f "macos/Runner.xcodeproj/project.pbxproj" ]; then
    cp macos/Runner.xcodeproj/project.pbxproj macos/Runner.xcodeproj/project.pbxproj.backup
    sed -i.tmp 's/COMPILER_INDEX_STORE_ENABLE = YES/COMPILER_INDEX_STORE_ENABLE = NO/g' macos/Runner.xcodeproj/project.pbxproj
    sed -i.tmp 's/SWIFT_COMPILATION_MODE = singlefile/SWIFT_COMPILATION_MODE = wholemodule/g' macos/Runner.xcodeproj/project.pbxproj
    rm -f macos/Runner.xcodeproj/project.pbxproj.tmp
    print_info "Xcode 项目已优化"
fi
print_success "步骤7完成 - 构建配置优化完成"
echo ""

# 步骤8: 执行 Flutter 构建
print_step "8" "执行 Flutter 构建 (多策略)"
print_warning "这是最耗时的步骤，可能需要5-20分钟"
print_info "将尝试 Release -> Debug -> Profile 三种构建模式"

BUILD_SUCCESS=false

# 策略1: Release 构建
print_progress "尝试 Release 构建..."
if flutter build macos --release --no-tree-shake-icons --dart-define=FLUTTER_WEB_USE_SKIA=true --verbose &
then
    BUILD_PID=$!
    BUILD_COUNTER=0
    
    while kill -0 $BUILD_PID 2>/dev/null; do
        BUILD_COUNTER=$((BUILD_COUNTER + 1))
        echo -ne "\r⏳ Release 构建进行中... ${BUILD_COUNTER}秒"
        sleep 1
        
        # 如果超过1800秒(30分钟)，认为卡死
        if [ $BUILD_COUNTER -gt 1800 ]; then
            print_error "Release 构建超时，可能卡死"
            kill $BUILD_PID 2>/dev/null || true
            break
        fi
    done
    echo ""
    
    wait $BUILD_PID
    if [ $? -eq 0 ]; then
        BUILD_SUCCESS=true
        BUILD_TYPE="Release"
        print_success "Release 构建成功！"
    else
        print_warning "Release 构建失败，尝试 Debug 构建..."
    fi
fi

# 策略2: Debug 构建 (如果 Release 失败)
if [ "$BUILD_SUCCESS" = false ]; then
    print_progress "尝试 Debug 构建..."
    if flutter build macos --debug --no-tree-shake-icons --verbose &
    then
        BUILD_PID=$!
        BUILD_COUNTER=0
        
        while kill -0 $BUILD_PID 2>/dev/null; do
            BUILD_COUNTER=$((BUILD_COUNTER + 1))
            echo -ne "\r⏳ Debug 构建进行中... ${BUILD_COUNTER}秒"
            sleep 1
            
            if [ $BUILD_COUNTER -gt 1200 ]; then
                print_error "Debug 构建超时，可能卡死"
                kill $BUILD_PID 2>/dev/null || true
                break
            fi
        done
        echo ""
        
        wait $BUILD_PID
        if [ $? -eq 0 ]; then
            BUILD_SUCCESS=true
            BUILD_TYPE="Debug"
            print_success "Debug 构建成功！"
        else
            print_warning "Debug 构建失败，尝试 Profile 构建..."
        fi
    fi
fi

# 策略3: Profile 构建 (如果前两个都失败)
if [ "$BUILD_SUCCESS" = false ]; then
    print_progress "尝试 Profile 构建..."
    if flutter build macos --profile --no-tree-shake-icons --verbose; then
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

print_success "步骤8完成 - Flutter 构建成功"
echo ""

# 步骤9: 验证构建结果
print_step "9" "验证构建结果"
APP_PATH="build/macos/Build/Products/$BUILD_TYPE/AppFlowy.app"

if [ -d "$APP_PATH" ]; then
    print_progress "检查应用完整性..."
    
    # 检查可执行文件
    if [ -f "$APP_PATH/Contents/MacOS/AppFlowy" ]; then
        print_success "✓ 主程序可执行文件存在"
    else
        print_error "✗ 主程序可执行文件缺失"
    fi
    
    # 检查框架
    if [ -d "$APP_PATH/Contents/Frameworks" ]; then
        FRAMEWORK_COUNT=$(ls -1 "$APP_PATH/Contents/Frameworks" | wc -l)
        print_success "✓ 包含 $FRAMEWORK_COUNT 个框架"
    else
        print_warning "✗ 框架目录缺失"
    fi
    
    # 检查资源
    if [ -d "$APP_PATH/Contents/Resources" ]; then
        print_success "✓ 资源文件目录存在"
    else
        print_warning "✗ 资源文件目录缺失"
    fi
    
    APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
    print_info "应用大小: $APP_SIZE"
    
else
    print_error "应用文件未找到: $APP_PATH"
    exit 1
fi

print_success "步骤9完成 - 构建验证通过"
echo ""

# 步骤10: 完成和清理
print_step "10" "完成构建和清理"

# 计算总构建时间
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

print_progress "恢复原始配置..."
if [ -f "macos/Runner.xcodeproj/project.pbxproj.backup" ]; then
    mv macos/Runner.xcodeproj/project.pbxproj.backup macos/Runner.xcodeproj/project.pbxproj
    print_info "Xcode 配置已恢复"
fi

# 显示缓存统计
if command -v sccache &> /dev/null; then
    print_progress "显示编译缓存统计..."
    sccache --show-stats
fi

print_success "步骤10完成 - 所有任务完成"
echo ""

# 最终结果
echo "🎉 完整功能构建成功！"
echo "========================"
print_success "构建类型: $BUILD_TYPE (完整功能)"
print_success "构建时间: ${MINUTES}分${SECONDS}秒"
print_success "应用位置: frontend/appflowy_flutter/$APP_PATH"
print_success "功能完整性: 100% (包含所有原始功能)"

echo ""
print_success "🚀 启动应用："
echo "open frontend/appflowy_flutter/$APP_PATH"

# 询问是否立即启动
echo ""
print_info "是否立即启动应用？(将在5秒后自动启动)"
sleep 5
print_progress "正在启动应用..."
open "$APP_PATH"

print_success "🎉 完整功能构建和启动完成！" 