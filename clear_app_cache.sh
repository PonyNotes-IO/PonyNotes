#!/bin/bash

echo "清除 PonyNotes 应用缓存和本地配置..."

# macOS 路径
MACOS_PATHS=(
    "$HOME/Library/Application Support/com.appflowy.appflowy"
    "$HOME/Library/Application Support/AppFlowy"
    "$HOME/Library/Caches/com.appflowy.appflowy"
    "$HOME/Library/Caches/AppFlowy"
    "$HOME/Library/Preferences/com.appflowy.appflowy.plist"
)

# Linux 路径
LINUX_PATHS=(
    "$HOME/.local/share/AppFlowy"
    "$HOME/.config/AppFlowy"
    "$HOME/.cache/AppFlowy"
)

echo "检测操作系统..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "检测到 macOS 系统"
    for path in "${MACOS_PATHS[@]}"; do
        if [ -e "$path" ]; then
            echo "删除: $path"
            rm -rf "$path"
        else
            echo "不存在: $path"
        fi
    done
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "检测到 Linux 系统"
    for path in "${LINUX_PATHS[@]}"; do
        if [ -e "$path" ]; then
            echo "删除: $path"
            rm -rf "$path"
        else
            echo "不存在: $path"
        fi
    done
else
    echo "不支持的操作系统: $OSTYPE"
    echo "请手动删除 AppFlowy 的应用数据目录"
fi

echo ""
echo "清除完成！请重新启动 PonyNotes 应用"
echo "应用将使用 dev.env 文件中的正确配置："
echo "  - 服务器地址: https://api.xiaomabiji.com"
echo "  - 认证类型: Self-hosted Cloud (类型3)"
