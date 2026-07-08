#!/bin/bash

# 切换到脚本所在目录，确保相对路径正确
cd "$(dirname "$0")" || exit

echo "======================================"
echo "请选择要执行的操作："
echo "1. 正常部署 (运行 site.yml)"
echo "2. 先清空 Kodi 数据库，再部署"
echo "3. 仅清空 Kodi 数据库"
echo "4. 检查 Kodi 数据库"
echo "0. 退出 (默认)"
echo "======================================"
read -r -p "请输入选项 [0]: " choice

case "$choice" in
    1)
        ;;
    2)
        echo ">>> 开始清空 Kodi 数据库..."
        ansible-playbook reset_kodi_db.yml
        ;;
    3)
        echo ">>> 开始清空 Kodi 数据库..."
        ansible-playbook reset_kodi_db.yml
        echo ">>> 清理完毕，退出。"
        exit 0
        ;;
    4)
        echo ">>> 开始检查 Kodi 数据库..."
        python3 check_kodi_db.py
        echo ">>> 检查完毕，退出。"
        exit 0
        ;;
    *)
        echo ">>> 已退出。"
        exit 0
        ;;
esac

# 从 all.yml 或 group_vars/all.yml 中提取 IP（兼容带空格和引号的格式）
# 假设变量名为 tv_ip 或 ansible_host
EXTRACTED_IP=$(grep -hE '^\s*(tv_ip|ansible_host)\s*:' all.yml group_vars/all.yml 2>/dev/null | head -n 1 | awk -F':' '{print $2}' | tr -d '"'\'' ' | tr -d '\r')

if [ -n "$EXTRACTED_IP" ]; then
    TV_IP="$EXTRACTED_IP"
    echo ">>> 从 all.yml 读取到 TV IP: $TV_IP"
else
    TV_IP="192.168.50.220"
fi

# 连接到 Sony TV，失败直接退出
echo ">>> 连接 Sony TV (${TV_IP})..."
if ! adb connect "${TV_IP}:5555" 2>&1 | grep -q "connected"; then
    echo "【错误】无法连接到 ${TV_IP}:5555，请检查："
    echo "  1. TV 是否开机且屏幕已唤醒"
    echo "  2. TV 与本机是否在同一网段"
    echo "  3. TV 是否已开启网络 ADB 调试"
    exit 1
fi

# 运行 Ansible playbook
# 支持附加参数，例如：./apply.sh -v 或 ./apply.sh --tags apps
ansible-playbook site.yml "$@"