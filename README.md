# Ansible_Sony_TV_X75H

本项目基于 Ansible 自动化工具，对 Sony Bravia X75H Android TV 进行净化改造。
包含禁用预装遥测/广告/冗余应用、安装第三方应用、配置 Kodi 及自定义桌面启动器的完整流程。

---

## 0. 目标设备规格

| 参数 | 规格 |
|------|------|
| 型号 | Sony Bravia KD-X75H |
| 操作系统 | Android TV 10 / 11 |
| 内核架构 | armv7l（32-bit） |
| ADB 权限 | 普通 shell，无 root |
| ADB 连接 | Wi-Fi，IP `192.168.50.220`，端口 `5555` |

> **架构说明**：`uname -a` 输出 `armv7l`，确认为 32-bit 系统。虽然 SoC 硬件可能为 64-bit，但 Sony 出厂系统为 32-bit 内核，所有 APK 必须选择 **armeabi-v7a** 架构版本。

> **Root 说明**：Sony Bravia X75H 无任何可用 root 方案，bootloader 完全锁死，`adb root` 直接拒绝。本项目所有操作均在普通 ADB shell 权限下完成，无法写入 `/system` 分区。

---

## 1. 前置条件

- 控制节点已安装 `adb` 和 `ansible`
- TV 已开启开发者模式及网络 ADB 调试（设置 → 关于 → 连续点击版本号）
- 所有 APK 已手动下载并放入 `roles/apps/files/`（见第 3 节）

---

## 2. 执行部署

```bash
./apply.sh
```

部署顺序：

1. ADB 连接验证
2. 批量禁用遥测、广告、冗余应用
3. 安装所有 APK
4. 设置 Projectivy 为默认桌面
5. 部署 Kodi 字体、sources.xml、splash 图
6. 最终状态验收检查

---

## 3. APK 清单

> 所有 APK 手动下载后放入 `roles/apps/files/`。

### 应用选型说明

**YouTube 无广告**：AdGuard for Android TV 官方文档明确说明无法过滤 HTTPS 流量，因此**无法拦截 YouTube 广告**。正确方案是使用第三方客户端绕过广告机制：

- **NewPipe**：轻量，无需账号，完全无广告
- **SmartTube**：专为 Android TV 遥控器优化，内置 SponsorBlock，支持登录 Google 账号查看订阅与历史，是电视上看 YouTube 的最佳体验

> **SmartTube 安全事件**：2025 年 11 月部分版本（30.43、30.47）因开发者编译机器遭入侵被植入恶意代码，30.56 起已修复并更换签名。只从官方 GitHub `github.com/yuliskov/SmartTube` 下载。

**浏览器**：Firefox (fenix) 是目前 Android 上唯一支持 WebExtension（uBlock Origin 等）的浏览器，遥控器操控体验较差但无更好替代。

**Solid Explorer**：**2.8.63 是最后一个提供独立单 APK 的版本**。3.x 起改为 XAPK Bundle，标准 `adb install -r` 无法安装。

### 下载地址

| 应用 | 架构 | 下载 |
|------|------|------|
| **NewPipe** | universal | `https://github.com/TeamNewPipe/NewPipe/releases/latest/download/NewPipe.apk`（固定 URL，永远最新） |
| **SmartTube** | armeabi-v7a | `https://github.com/yuliskov/SmartTube/releases/latest/download/SmartTube_stable_armeabi-v7a.apk`（固定 URL，永远最新） |
| **VLC** | armeabi-v7a | `https://get.videolan.org/vlc-android/3.7.0/VLC-Android-3.7.0-armeabi-v7a.apk`（升级时修改 URL 中版本号） |
| **Kodi** | armeabi-v7a | `https://mirrors.kodi.tv/releases/android/arm/kodi-21.3-Omega-armeabi-v7a.apk`（升级时修改 URL 中版本号） |
| **Firefox (fenix)** | armeabi-v7a | `https://ftp.mozilla.org/pub/fenix/releases/` 选版本后下载对应 `fenix-{版本}-armeabi-v7a.apk` |
| **Projectivy Launcher** | universal | APKMirror: `apkmirror.com/apk/spocky/projectivy-launcher-android-tv/` |
| **Solid Explorer** | armeabi-v7a | APKMirror: `apkmirror.com/apk/neatbytes/solid-explorer-file-manager/solid-explorer-file-manager-2-8-63-release/solid-explorer-file-manager-2-8-63-3-android-apk-download/`（**最后单 APK 版，勿升级至 3.x**） |

---

## 4. 禁用应用列表

全部使用 `pm disable-user --user 0`，可随时通过 `pm enable <包名>` 恢复。

### 遥测 / 隐私

| 包名 | 说明 |
|------|------|
| `tv.samba.ssm` | Samba TV 行为追踪主服务 |
| `tv.samba.gat` | Samba TV ACR，自动识别收视内容并上报 |
| `com.sony.dtv.watchtvrecommendation` | 监控收视行为上报 |
| `com.sony.dtv.networkrecommendation` | 网络行为追踪 |
| `com.sony.dtv.irbrecommendation` | 遥控按键习惯追踪 |
| `com.sony.dtv.woprecommendation` | 开机行为追踪 |
| `com.sony.dtv.recommendationservice` | 推荐引擎主服务（聚合上述追踪数据） |
| `com.sony.qrmt` | Sony 远程诊断服务 |
| `com.google.android.feedback` | Google 崩溃/使用数据上报 |

### 广告 / 推广

| 包名 | 说明 |
|------|------|
| `com.google.android.tvrecommendations` | Google TV 主页广告推荐栏 |
| `com.sony.dtv.sonyselect` | Sony Select 广告精选内容 |
| `com.sony.dtv.sonyselect.overlay` | Sony Select 覆盖层 |
| `com.sony.dtv.discovery` | 内容探索推荐（广告驱动） |
| `com.sony.snei.video.hhvu` | Sony 视频推广服务 |
| `com.sony.dtv.bravialifehack` | Bravia Life Hack 广告内容 |

### Sony 无用功能

| 包名 | 说明 |
|------|------|
| `com.sony.dtv.demo` | 零售演示模式 |
| `com.sony.dtv.demomode` | 演示模式核心服务 |
| `com.sony.dtv.demosupport` | 演示支持服务 |
| `com.sony.dtv.multiscreendemo` | 多屏演示 |
| `com.sony.dtv.smarthelp` | Smart Help 客服入口 |
| `com.sony.dtv.customersupport` | 客户支持应用 |
| `com.sony.dtv.imanual` | 电子说明书 |
| `com.sony.dtv.eulaviewer` | EULA 弹窗服务（初始化后永久无用） |
| `com.sony.dtv.interactive.tv.service` | 互动 TV 平台（HbbTV）⚠️ 见故障排除 |

### Google 冗余

| 包名 | 说明 |
|------|------|
| `com.google.android.videos` | Google Play 影视 |
| `com.google.android.youtube.tvmusic` | YouTube Music TV 版 |
| `com.google.android.play.games` | Google Play 游戏 |
| `com.google.android.marvin.talkback` | TalkBack 无障碍朗读 |
| `com.google.android.tts` | Google TTS 引擎 |
| `com.google.android.tvtutorials` | Android TV 使用教程 |
| `com.google.android.katniss` | Google 语音搜索（禁用后遥控麦克风失效） |

---

## 5. 项目文件结构

```
Ansible_Sony_TV_X75H/
├── site.yml
├── apply.sh
├── roles/
│   ├── system_init/
│   │   ├── defaults/
│   │   │   └── main.yml          # 四类应用禁用列表
│   │   └── tasks/
│   │       ├── main.yml
│   │       ├── connect.yml       # ADB 连接与在线验证
│   │       └── clear.yml         # pm disable-user 批量禁用
│   └── apps/
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── install_apks.yml  # adb install -r 安装 APK
│       │   ├── launcher.yml      # Projectivy 设为默认桌面
│       │   ├── kodi.yml          # Kodi 字体/sources/splash
│       │   └── status.yml        # 最终验收检查
│       └── files/
│           ├── kodi/
│           │   ├── sources.xml
│           │   └── advancedsettings.xml
│           └── fonts/            # Kodi 中文字体
```

---

## 6. 部署后手动配置

### Kodi 首次启动设置

```
Interface → 底部切换 Standard 到 Expert
Interface → Font → 改为 ArialBased
Player → Subtitle → Font → 改为已推送的 NotoSC 字体名
```

### Projectivy Launcher

首次启动完成初始化引导即可。如需授权悬浮窗：

```bash
adb shell appops set com.spocky.projengmenu SYSTEM_ALERT_WINDOW allow
```

### SmartTube

内置自动更新检测，有新版本时应用内提示，无需手动维护 APK。

---

## 7. 故障排除

**禁用 `com.sony.dtv.interactive.tv.service` 后系统设置无法打开**

```bash
adb shell pm enable com.sony.dtv.interactive.tv.service
```

**按 Home 键仍回到 Sony 原生界面**

```bash
adb shell pm disable-user --user 0 com.google.android.tvlauncher
```

恢复：

```bash
adb shell pm enable com.google.android.tvlauncher
```

**ADB 连接失败 / 设备离线**

Android TV 息屏后 ADB Wi-Fi 会静默断开，先唤醒屏幕再重连：

```bash
adb connect 192.168.50.220:5555
```

**APK 安装失败，提示空间不足**

```bash
adb shell pm uninstall <包名>
# 再重新执行 apply.sh
```
