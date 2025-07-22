#!/bin/bash

# ⚡ 小马笔记 - 超快速构建脚本
# 跳过耗时步骤，直接使用已有构建结果

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}⚡ $1${NC}"
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

echo "⚡ 小马笔记 - 超快速构建 (30秒完成)"
echo "====================================="

# 记录开始时间
START_TIME=$(date +%s)

# 1. 检查是否已有构建结果
print_info "检查已有构建结果..."

cd frontend/appflowy_flutter

# 检查是否已有可用的构建
EXISTING_BUILD=""
if [ -d "build/macos/Build/Products/Release/AppFlowy.app" ]; then
    EXISTING_BUILD="build/macos/Build/Products/Release/AppFlowy.app"
    BUILD_TYPE="Release"
elif [ -d "build/macos/Build/Products/Debug/AppFlowy.app" ]; then
    EXISTING_BUILD="build/macos/Build/Products/Debug/AppFlowy.app"
    BUILD_TYPE="Debug"
elif [ -d "build/macos/Build/Products/Profile/AppFlowy.app" ]; then
    EXISTING_BUILD="build/macos/Build/Products/Profile/AppFlowy.app"
    BUILD_TYPE="Profile"
fi

if [ ! -z "$EXISTING_BUILD" ]; then
    print_success "发现已有构建: $BUILD_TYPE"
    
    # 快速验证构建完整性
    if [ -f "$EXISTING_BUILD/Contents/MacOS/AppFlowy" ]; then
        print_success "构建完整，跳过重新编译"
        
        # 计算时间
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        print_success "超快速构建完成！"
        print_info "构建类型: $BUILD_TYPE (复用已有)"
        print_info "用时: ${DURATION}秒"
        
        APP_SIZE=$(du -sh "$EXISTING_BUILD" | cut -f1)
        print_info "应用大小: $APP_SIZE"
        
        echo ""
        print_success "🎉 立即启动应用："
        echo "open frontend/appflowy_flutter/$EXISTING_BUILD"
        
        # 直接启动应用
        print_info "正在启动应用..."
        open "$EXISTING_BUILD"
        
        exit 0
    fi
fi

# 2. 如果没有已有构建，执行最小化快速构建
print_info "没有可用构建，执行最小化快速构建..."

# 设置最快的构建环境
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 跳过清理，直接获取依赖
print_info "快速获取依赖..."
flutter pub get --offline 2>/dev/null || flutter pub get

# 3. 尝试最快的构建方式
print_info "执行超快速构建..."

# 策略1: 使用缓存的增量构建
if flutter build macos --debug --no-tree-shake-icons --no-pub; then
    BUILD_TYPE="Debug"
    APP_PATH="build/macos/Build/Products/Debug/AppFlowy.app"
    print_success "增量构建成功！"
elif flutter build macos --debug --no-tree-shake-icons; then
    BUILD_TYPE="Debug"
    APP_PATH="build/macos/Build/Products/Debug/AppFlowy.app"
    print_success "快速构建成功！"
else
    print_error "快速构建失败，请使用完整构建脚本"
    echo "运行: ./scripts/full_feature_build.sh"
    exit 1
fi

# 4. 构建完成处理
if [ -d "$APP_PATH" ]; then
    # 计算构建时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    print_success "超快速构建完成！"
    print_info "构建类型: $BUILD_TYPE"
    if [ $MINUTES -gt 0 ]; then
        print_info "构建时间: ${MINUTES}分${SECONDS}秒"
    else
        print_info "构建时间: ${SECONDS}秒"
    fi
    
    # 显示应用信息
    APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
    print_info "应用大小: $APP_SIZE"
    
    # 快速验证
    if [ -f "$APP_PATH/Contents/MacOS/AppFlowy" ]; then
        print_success "✓ 应用可执行"
    fi
    
    echo ""
    print_success "🎉 立即启动应用："
    echo "open frontend/appflowy_flutter/$APP_PATH"
    
    # 直接启动应用
    print_info "正在启动应用..."
    open "$APP_PATH"
    
else
    print_error "构建失败"
    exit 1
fi

print_success "⚡ 超快速构建完成！应用已启动！" 