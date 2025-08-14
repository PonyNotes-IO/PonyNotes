#!/bin/bash

# 临时禁用代理运行Flutter应用
export NO_PROXY="localhost,127.0.0.1,::1,*.local"
export no_proxy="localhost,127.0.0.1,::1,*.local"
export HTTP_PROXY=""
export HTTPS_PROXY=""
export http_proxy=""
export https_proxy=""

echo "禁用代理，启动Flutter应用..."
cd appflowy_flutter
flutter run --debug

