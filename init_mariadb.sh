#!/bin/bash

cd "$(dirname "$0")" || exit

echo ">>> 初始化 Kodi MariaDB..."

echo "注：第一次运行将创建 Kodi MariaDB 用户权限。"
echo "如果 MyVideos131 仍不可用，请先执行 site.yml 推送 advancedsettings.xml，并在 Sony TV 上启动 Kodi 一次。"
echo "完成后再次运行本脚本完成媒体路径写入。"

ansible-playbook site_mariadb.yml "$@"
