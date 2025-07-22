#!/bin/bash

# 🌐 小马笔记 - 离线构建脚本
# 处理网络依赖问题，但保留所有原始功能

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

echo "🌐 小马笔记 - 离线构建 (保留完整功能)"
echo "======================================="

# 记录开始时间
START_TIME=$(date +%s)

# 1. 设置网络优化环境
print_info "设置网络优化环境..."
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export RUSTC_WRAPPER=sccache
export CARGO_INCREMENTAL=1
export CARGO_BUILD_JOBS=$(sysctl -n hw.ncpu)

# 2. 进入 Flutter 项目目录
cd frontend/appflowy_flutter

# 3. 检查并处理网络依赖
print_info "检查网络依赖状态..."

# 检查 super_native_extensions 是否可用
SUPER_NATIVE_AVAILABLE=false
if flutter pub deps | grep -q "super_native_extensions"; then
    print_info "检测到 super_native_extensions 依赖"
    
    # 尝试预下载依赖
    print_info "尝试预下载网络依赖..."
    if timeout 60 flutter pub get; then
        SUPER_NATIVE_AVAILABLE=true
        print_success "网络依赖下载成功"
    else
        print_warning "网络依赖下载超时，将使用离线模式"
    fi
else
    print_info "未检测到网络依赖"
    SUPER_NATIVE_AVAILABLE=true
fi

# 4. 根据网络依赖状态选择构建策略
if [ "$SUPER_NATIVE_AVAILABLE" = true ]; then
    print_info "使用完整功能构建..."
    
    # 完整功能构建
    print_info "获取所有依赖..."
    flutter pub get
    
    # 构建完整版本
    print_info "执行完整功能构建..."
    if flutter build macos --release; then
        BUILD_TYPE="Release (完整功能)"
        APP_PATH="build/macos/Build/Products/Release/AppFlowy.app"
        print_success "完整功能构建成功！"
    elif flutter build macos --debug; then
        BUILD_TYPE="Debug (完整功能)"
        APP_PATH="build/macos/Build/Products/Debug/AppFlowy.app"
        print_success "完整功能调试构建成功！"
    else
        print_error "完整功能构建失败"
        exit 1
    fi
    
else
    print_info "使用离线兼容模式构建..."
    
    # 备份原始 pubspec.yaml
    cp pubspec.yaml pubspec.yaml.backup
    
    # 创建离线兼容的 pubspec.yaml
    print_info "创建离线兼容配置..."
    
    # 注释掉可能有网络问题的依赖，但保留其他功能
    sed -i.tmp '/super_clipboard:/s/^/  # OFFLINE_DISABLED: /' pubspec.yaml
    sed -i.tmp '/super_native_extensions:/s/^/  # OFFLINE_DISABLED: /' pubspec.yaml
    
    # 添加替代依赖 (如果需要)
    cat >> pubspec.yaml << 'EOF'

# 离线模式替代依赖
  # 使用系统剪贴板的简单实现
  # super_clipboard 的功能将通过其他方式实现
EOF

    # 获取离线依赖
    print_info "获取离线兼容依赖..."
    flutter pub get
    
    # 创建离线兼容的代码修改
    print_info "应用离线兼容代码修改..."
    
    # 查找并修改使用 super_clipboard 的文件
    find lib -name "*.dart" -type f | while read file; do
        if grep -q "super_clipboard\|super_native_extensions" "$file"; then
            print_info "修改文件: $file"
            # 备份原文件
            cp "$file" "$file.backup"
            
            # 注释掉相关导入
            sed -i.tmp 's/import.*super_clipboard.*/\/\/ OFFLINE_DISABLED: &/' "$file"
            sed -i.tmp 's/import.*super_native_extensions.*/\/\/ OFFLINE_DISABLED: &/' "$file"
            
            # 清理临时文件
            rm -f "$file.tmp"
        fi
    done
    
    # 构建离线版本
    print_info "执行离线兼容构建..."
    if flutter build macos --release; then
        BUILD_TYPE="Release (离线兼容)"
        APP_PATH="build/macos/Build/Products/Release/AppFlowy.app"
        print_success "离线兼容构建成功！"
    elif flutter build macos --debug; then
        BUILD_TYPE="Debug (离线兼容)"
        APP_PATH="build/macos/Build/Products/Debug/AppFlowy.app"
        print_success "离线兼容调试构建成功！"
    else
        print_error "离线兼容构建失败"
        
        # 恢复原始文件
        print_info "恢复原始文件..."
        mv pubspec.yaml.backup pubspec.yaml
        find lib -name "*.dart.backup" -type f | while read backup; do
            original="${backup%.backup}"
            mv "$backup" "$original"
        done
        
        exit 1
    fi
    
    # 恢复原始文件
    print_info "恢复原始文件..."
    mv pubspec.yaml.backup pubspec.yaml
    find lib -name "*.dart.backup" -type f | while read backup; do
        original="${backup%.backup}"
        mv "$backup" "$original"
    done
    
    print_warning "注意: 此版本可能缺少一些剪贴板相关功能"
    print_info "在网络条件好的时候，建议使用完整功能构建"
fi

# 5. 构建后处理和验证
if [ -d "$APP_PATH" ]; then
    # 计算构建时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    print_success "构建完成！"
    print_info "构建类型: $BUILD_TYPE"
    print_info "构建时间: ${MINUTES}分${SECONDS}秒"
    
    # 显示应用信息
    APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
    print_info "应用大小: $APP_SIZE"
    print_info "应用位置: frontend/appflowy_flutter/$APP_PATH"
    
    # 验证应用完整性
    print_info "验证应用完整性..."
    
    # 检查可执行文件
    if [ -f "$APP_PATH/Contents/MacOS/AppFlowy" ]; then
        print_success "✓ 主程序可执行文件"
    else
        print_error "✗ 主程序可执行文件缺失"
    fi
    
    # 检查 Info.plist
    if [ -f "$APP_PATH/Contents/Info.plist" ]; then
        print_success "✓ 应用信息文件"
        
        # 检查应用名称
        APP_NAME=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleDisplayName | cut -d'"' -f4)
        if [ ! -z "$APP_NAME" ]; then
            print_info "应用名称: $APP_NAME"
        fi
    else
        print_warning "✗ 应用信息文件缺失"
    fi
    
    # 检查框架
    if [ -d "$APP_PATH/Contents/Frameworks" ]; then
        FRAMEWORK_COUNT=$(ls -1 "$APP_PATH/Contents/Frameworks" | wc -l)
        print_success "✓ 包含 $FRAMEWORK_COUNT 个框架"
        
        # 检查关键框架
        if [ -d "$APP_PATH/Contents/Frameworks/FlutterMacOS.framework" ]; then
            print_success "✓ Flutter 框架"
        else
            print_warning "✗ Flutter 框架缺失"
        fi
    else
        print_warning "✗ 框架目录缺失"
    fi
    
    # 检查资源文件
    if [ -d "$APP_PATH/Contents/Resources" ]; then
        print_success "✓ 资源文件目录"
    else
        print_warning "✗ 资源文件目录缺失"
    fi
    
    # 提供启动命令
    echo ""
    print_success "🎉 构建完成！启动应用："
    echo "open frontend/appflowy_flutter/$APP_PATH"
    echo ""
    print_info "或者双击应用图标启动"
    
    # 显示功能说明
    echo ""
    if [ "$SUPER_NATIVE_AVAILABLE" = true ]; then
        print_info "✅ 完整功能版本 - 包含所有原始功能"
    else
        print_warning "⚠️  离线兼容版本 - 可能缺少部分剪贴板功能"
        print_info "建议在网络条件好的时候重新构建完整版本"
    fi
    
else
    print_error "应用文件未找到: $APP_PATH"
    exit 1
fi

# 显示缓存统计
if command -v sccache &> /dev/null; then
    echo ""
    print_info "Rust 编译缓存统计:"
    sccache --show-stats
fi

print_success "离线构建脚本执行完成！" 