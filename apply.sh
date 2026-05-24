#!/bin/bash

# 切换到脚本所在目录，确保相对路径正确
cd "$(dirname "$0")" || exit

# 连接到 Sony TV，失败直接退出
echo ">>> 连接 Sony TV..."
if ! adb connect 192.168.50.220:5555 2>&1 | grep -q "connected"; then
    echo "【错误】无法连接到 192.168.50.220:5555，请检查："
    echo "  1. TV 是否开机且屏幕已唤醒"
    echo "  2. TV 与本机是否在同一网段"
    echo "  3. TV 是否已开启网络 ADB 调试"
    exit 1
fi

# 运行 Ansible playbook
# 支持附加参数，例如：./apply.sh -v 或 ./apply.sh --tags apps
ansible-playbook site.yml "$@"