#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")" || exit

TV_IP="192.168.50.220"
ADB="adb -s ${TV_IP}:5555"
KODI_DATA="/storage/emulated/0/Android/data/org.xbmc.kodi/files/.kodi"
DEST_KODI="roles/apps/files/kodi"
DEST_FONTS="roles/apps/files/fonts"
DEST_ADDONS="roles/apps/files/addons"

echo ">>> 备份 Kodi 配置到本地"

echo ">>> 连接 TV ${TV_IP}..."
if ! $ADB connect "${TV_IP}:5555" 2>&1 | grep -Eq "connected|already connected"; then
  echo "【错误】无法连接到 ${TV_IP}:5555。请检查 TV 是否已打开 ADB。"
  exit 1
fi

echo ">>> 创建本地备份目录"
mkdir -p "$DEST_KODI" "$DEST_FONTS" "$DEST_ADDONS"

echo ">>> 拉取 guisettings.xml"
$ADB pull "${KODI_DATA}/userdata/guisettings.xml" "${DEST_KODI}/guisettings.xml"

echo ">>> 拉取 Fonts 目录"
$ADB pull "${KODI_DATA}/media/Fonts" "$DEST_FONTS"

echo ">>> 备份完成。请检查 ${DEST_KODI} 和 ${DEST_FONTS}"
