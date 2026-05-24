#!/bin/bash

# 配置与变量
TV_IP="192.168.50.220"
NAS_IP="192.168.50.210"
KODI_DATA="/sdcard/Android/data/org.xbmc.kodi/files/.kodi"


# 颜色定义
Y='\033[1;33m'
G='\033[1;32m'
R='\033[1;31m'
NC='\033[0m'


# ── NAS 检查清单 ──────────────────────────────────────────
echo -e "${Y}====================================================${NC}"
echo -e "${Y} [NAS 检查清单] IP: $NAS_IP${NC}"
echo -e "${Y}  1. 开启 NFS 服务并允许 192.168.50.0/24 访问${NC}"
echo -e "${Y}  2. 勾选 'Insecure' (非特权端口) 选项${NC}"
echo -e "${Y}  3. 设置为 'No Squash' (确保文件权限一致)${NC}"
echo -e "${Y}====================================================${NC}"
read -p "NAS 确认已配置好? (y/n): " confirm
[[ $confirm != "y" ]] && exit 1


# ── 连通性测试 ────────────────────────────────────────────
echo -e "\n${Y}>>> 连通性测试${NC}"
adb connect $TV_IP:5555
adb wait-for-device
echo -e "${G}[OK] ADB 已连接 $TV_IP${NC}"

if ! ping -c 1 -W 2 $NAS_IP > /dev/null 2>&1; then
    echo -e "${R}[错误] 无法 Ping 通 NAS $NAS_IP，请检查网络${NC}"
    exit 1
fi
echo -e "${G}[OK] NAS $NAS_IP 网络可达${NC}"


# ── 系统深度净化 ──────────────────────────────────────────
echo -e "\n${Y}>>> 系统深度净化${NC}"

MONITORING=("com.sony.qrmt" "tv.samba.ssm" "tv.samba.gat" "com.sony.dtv.interactive.tv.service" "com.sony.dtv.smarthelp")
ADVERTISING=("com.google.android.tvrecommendations" "com.sony.dtv.demo" "com.sony.dtv.eulaviewer")
BLOATWARE=("com.google.android.videos" "com.google.android.youtube.tvmusic" "com.google.android.feedback")

safe_disable() {
    for app in "$@"; do
        if adb shell pm list packages | grep -q "$app"; then
            adb shell pm disable-user --user 0 "$app" > /dev/null 2>&1
            echo -e "${G}[已禁用]${NC} $app"
        else
            echo -e "${Y}[跳过]${NC} $app (未发现)"
        fi
    done
}

safe_disable "${MONITORING[@]}"
safe_disable "${ADVERTISING[@]}"
safe_disable "${BLOATWARE[@]}"


# ── 协议栈恢复 ────────────────────────────────────────────
echo -e "\n${Y}>>> 协议栈恢复${NC}"
adb shell settings put global captive_portal_mode 1 > /dev/null 2>&1
adb shell settings put global captive_portal_detection_enabled 1 > /dev/null 2>&1
echo -e "${G}[OK] 网络连接检测已恢复${NC}"


# ── 安装 APK ──────────────────────────────────────────────
echo -e "\n${Y}>>> 安装 APK${NC}"
if [ -d "apks" ]; then
    for apk in apks/*.apk; do
        echo -e "${Y}[安装]${NC} $(basename "$apk")"
        adb install -r -g "$apk" > /dev/null 2>&1
        echo -e "${G}[OK]${NC} $(basename "$apk")"
    done
else
    echo -e "${Y}[跳过]${NC} 未发现 apks 目录"
fi


# ── 桌面锁定 ──────────────────────────────────────────────
echo -e "\n${Y}>>> 桌面锁定${NC}"
adb shell cmd package set-home-activity com.spocky.projengmenu/com.spocky.projengmenu.ui.home.MainActivity > /dev/null 2>&1
echo -e "${G}[OK] Projectivy 已设为默认桌面${NC}"


# ── Kodi 配置部署 ─────────────────────────────────────────
echo -e "\n${Y}>>> Kodi 配置部署${NC}"
adb shell am force-stop org.xbmc.kodi
echo -e "${G}[OK] Kodi 已强制停止${NC}"

# 字体
if [ -d "fonts" ]; then
    adb shell "mkdir -p $KODI_DATA/media/Fonts"
    adb push fonts/ "$KODI_DATA/media/" > /dev/null 2>&1
    echo -e "${G}[OK] 字体文件已同步${NC}"
else
    echo -e "${Y}[跳过]${NC} 未发现 fonts 目录"
fi

# sources.xml
if [[ -f "sources.xml" ]]; then
    adb shell "rm $KODI_DATA/userdata/sources.xml 2>/dev/null" || true
    adb push sources.xml "$KODI_DATA/userdata/sources.xml" > /dev/null 2>&1
    echo -e "${G}[OK] sources.xml 已更新${NC}"
else
    echo -e "${Y}[跳过]${NC} 未发现 sources.xml，请进入 Kodi 手动添加视频源"
fi

# advancedsettings.xml / splash.jpg (二选一，splash 优先)
if [[ -f "splash.jpg" ]]; then
    [[ -f "advancedsettings.xml" ]] && echo -e "${Y}[跳过]${NC} 检测到 splash.jpg，忽略 advancedsettings.xml"
    adb shell "mkdir -p $KODI_DATA/media"
    adb shell "rm $KODI_DATA/media/splash.jpg $KODI_DATA/media/splash.png 2>/dev/null" || true
    adb shell "rm $KODI_DATA/userdata/advancedsettings.xml 2>/dev/null" || true
    adb push "splash.jpg" "$KODI_DATA/media/splash.jpg" > /dev/null 2>&1
    echo -e "${G}[OK] Splash 画面已更新${NC}"
elif [[ -f "advancedsettings.xml" ]]; then
    adb push advancedsettings.xml "$KODI_DATA/userdata/" > /dev/null 2>&1
    echo -e "${G}[OK] advancedsettings.xml 已更新${NC}"
else
    echo -e "${Y}[跳过]${NC} 未发现 splash.jpg 或 advancedsettings.xml"
fi


# ── 完成 ──────────────────────────────────────────────────
echo -e "\n${G}====================================================${NC}"
echo -e "${G} 部署成功！请进入 Kodi 完成以下手动设置：${NC}"
echo -e "${Y}  a. Interface → 切换底部 Standard 到 Expert${NC}"
echo -e "${Y}  b. Interface → Font → 改为 ArialBased${NC}"
echo -e "${Y}  c. Player → Subtitle → Font → 改为 NotoSC-simibold${NC}"
echo -e "${G}====================================================${NC}"
