#!/bin/bash

# 切换到脚本所在目录，确保相对路径正确
cd "$(dirname "$0")" || exit

echo "======================================"
echo "1. 正常部署 (site.yml)                 - 全自动安装和配置环境，适用于新装或重置电视"
echo "2. 清空 Kodi 数据库 (重置)             - 当数据混乱或刮削错误严重时，一键彻底清空 MariaDB 中的媒体库数据"
echo "3. 检查并修复 Kodi 媒体库 (查漏+重扫)  - 找出未成功入库的哑火文件，并可选择清除哈希强制 Kodi 深度重扫"
echo "4. 从电视拉取 Kodi 运行日志            - 提取电视端 Kodi 的调试日志 (kodi.log) 到本地用于排错"
echo "5. 修复/同步 Kodi 媒体路径内容类型     - 解决 Kodi 媒体类型丢失问题，强制将目录与 movies/tvshows 类型绑定"
echo "0. 退出 (默认)"
echo "=========================================================================================="
read -r -p "请输入选项 [0]: " choice

case "$choice" in
    1)
        ;;
    2)
        echo ">>> 开始清空 Kodi 数据库..."
        ansible-playbook tools/reset_kodi_db.yml
        echo "--------------------------------------"
        read -r -p "数据库已清空，是否继续执行完整的电视环境部署? (y/N): " deploy_choice
        if [[ "$deploy_choice" =~ ^[Yy]$ ]]; then
            echo ">>> 继续执行部署..."
            # 走到这里不 exit，就会继续执行脚本底部的 site.yml 逻辑
        else
            echo ">>> 任务完成，退出。"
            exit 0
        fi
        ;;
    3)
        echo ">>> 开始检查 Kodi 数据库..."
        ansible-playbook tools/check_db.yml
        echo "--------------------------------------"
        read -r -p "是否需要清除哈希缓存并强制 Kodi 重新扫描以修复遗漏? (y/N): " rescan_choice
        if [[ "$rescan_choice" =~ ^[Yy]$ ]]; then
            echo ">>> 开始强制 Kodi 深度重扫..."
            ansible-playbook tools/force_rescan.yml
            echo ">>> 触发完毕！请前往电视查看 Kodi 扫描进度。"
        else
            echo ">>> 检查完毕，退出。"
        fi
        exit 0
        ;;
    4)
        echo ">>> 正在从电视拉取 Kodi 日志..."
        ansible-playbook tools/fetch_kodi_log.yml
        exit 0
        ;;
    5)
        echo ">>> 开始同步 Kodi 媒体路径内容类型..."
        ansible-playbook tools/sync_paths.yml
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