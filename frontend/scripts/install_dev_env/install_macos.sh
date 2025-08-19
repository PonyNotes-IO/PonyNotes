#!/usr/bin/env bash
# 指定脚本解释器为bash，确保脚本在不同系统上都能正确执行

# 定义终端颜色代码，用于美化输出信息
YELLOW="\e[93m"     # 黄色，用于一般信息提示
GREEN="\e[32m"      # 绿色，用于成功信息提示
RED="\e[31m"        # 红色，用于错误信息提示
ENDCOLOR="\e[0m"    # 重置颜色，回到默认终端颜色

# 定义打印黄色消息的函数（一般信息）
printMessage() {
   printf "${YELLOW}AppFlowy : $1${ENDCOLOR}\n"
}

# 定义打印绿色消息的函数（成功信息）
printSuccess() {
   printf "${GREEN}AppFlowy : $1${ENDCOLOR}\n"
}

# 定义打印红色消息的函数（错误信息）
printError() {
   printf "${RED}AppFlowy : $1${ENDCOLOR}\n"
}

# ========== 第一步：安装 Rust 编程语言 ==========
# AppFlowy 的核心后端是用 Rust 编写的，所以需要 Rust 编译器
printMessage "The Rust programming language is required to compile AppFlowy."
printMessage "We can install it now if you don't already have it on your system."

# 询问用户是否要安装 Rust，默认为 N（不安装）
read -p "$(printSuccess "Do you want to install Rust? [y/N]") " installrust

# 检查用户输入，如果是 Y 或 y 则安装 Rust
if [[ "${installrust:-N}" == [Yy] ]]; then
   printMessage "Installing Rust."
   # 使用 Homebrew 安装 rustup-init（Rust 安装器）
   brew install rustup-init
   # 运行 rustup-init 安装稳定版 Rust，-y 表示自动确认所有选项
   rustup-init -y --default-toolchain=stable

   # 加载 Rust 环境变量，使 cargo 命令可用
   source "$HOME/.cargo/env"
else
   printMessage "Skipping Rust installation."
fi

# ========== 第二步：安装 SQLite 数据库 ==========
# AppFlowy 使用 SQLite 作为本地数据存储
printMessage "Installing sqlLite3."
brew install sqlite3

# ========== 第三步：设置 Flutter 开发环境 ==========
printMessage "Setting up Flutter"

# 获取当前安装的 Flutter 版本号
# 使用 grep 正则表达式提取版本号
FLUTTER_VERSION=$(flutter --version | grep -oE 'Flutter [^ ]+' | grep -oE '[^ ]+$')

# 检查当前 Flutter 版本是否为 AppFlowy 要求的 3.27.4 版本
if [ "$FLUTTER_VERSION" = "3.27.4" ]; then
   echo "Flutter version is already 3.27.4"
else
   # 如果版本不匹配，需要切换到指定版本
   # 获取 Flutter SDK 的安装路径
   FLUTTER_PATH=$(which flutter)
   # 从完整路径中移除 /bin/flutter 部分，得到 SDK 根目录
   FLUTTER_PATH=${FLUTTER_PATH%/bin/flutter}

   # 保存当前工作目录
   current_dir=$(pwd)

   # 进入 Flutter SDK 目录
   cd $FLUTTER_PATH
   # 使用 git 切换到 3.27.4 版本（Flutter SDK 是通过 git 管理的）
   git checkout 3.27.4
   # 返回到原来的工作目录
   cd "$current_dir"

   echo "Switched to Flutter version 3.27.4"
fi

# ========== 第四步：启用 Flutter 桌面支持 ==========
# 启用 macOS 桌面应用开发支持（AppFlowy 是桌面应用）
flutter config --enable-macos-desktop

# ========== 第五步：检查 Flutter 开发环境 ==========
# 运行 flutter doctor 检查开发环境是否配置正确，并修复发现的问题
flutter doctor

# ========== 第六步：设置 Git 钩子 ==========
# Git 钩子用于在提交代码时自动执行代码检查和格式化
printMessage "Setting up githooks."
# 配置 git 使用项目中的 .githooks 目录作为钩子目录
git config core.hooksPath .githooks

# ========== 第七步：安装代码质量检查工具 ==========
# 安装 go-gitlint 工具，用于检查 git 提交信息的格式
printMessage "Installing go-gitlint."
GOLINT_FILENAME="go-gitlint_1.1.0_osx_x86_64.tar.gz"
# 从 GitHub 下载 go-gitlint 的 macOS 版本
curl -L https://github.com/llorllale/go-gitlint/releases/download/1.1.0/${GOLINT_FILENAME} --output ${GOLINT_FILENAME}
# 解压下载的文件到 .githooks 目录
tar -zxv --directory .githooks/. -f ${GOLINT_FILENAME} gitlint
# 删除下载的压缩包文件
rm ${GOLINT_FILENAME}

# ========== 第八步：进入前端项目目录 ==========
# 切换到 frontend 目录，如果切换失败则退出脚本（exit 1 表示异常退出）
cd frontend || exit 1

# ========== 第九步：安装 Rust 构建工具 ==========
# 安装 cargo-make，这是一个 Rust 项目的任务运行器，类似于 npm scripts
printMessage "Installing cargo-make."
cargo install --force cargo-make

# ========== 第十步：安装脚本语言工具 ==========
# 安装 duckscript，这是一个简单的脚本语言，用于跨平台的构建脚本
printMessage "Installing duckscript."
# --locked 确保使用 Cargo.lock 中指定的精确依赖版本
cargo install --force --locked duckscript_cli

# ========== 第十一步：检查依赖和工具 ==========
# 运行 cargo make 任务来检查 AppFlowy Flutter 项目的所有依赖工具是否正确安装
printMessage "Checking prerequisites."
cargo make appflowy-flutter-deps-tools
