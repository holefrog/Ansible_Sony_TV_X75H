# Ansible_Sony_TV_X75H

本项目基于 Ansible 自动化工具，对 Sony Bravia X75H Android TV 进行净化改造。
包含卸载/禁用预装广告与遥测应用、安装第三方应用、配置 Kodi 及自定义桌面启动器的完整流程。

---

## 0. 目标设备规格 (Target Device: Sony Bravia X75H)

| 参数 | 规格 |
|------|------|
| 型号 | Sony Bravia KD-X75H |
| 操作系统 | Android TV 10 / 11 |
| 内核架构 | **armv7l（32-bit）**，`uname -a` 输出 `armv7l` |
| ADB 权限 | 普通 shell（**无 root**，无法写入 `/system` 分区） |
| ADB 连接方式 | Wi-Fi，IP `192.168.50.220`，端口 `5555` |

> **重要架构说明**：虽然 X75H 的 SoC 硬件可能为 64-bit，但 Sony 出厂系统为 32-bit 内核。
> 所有 APK 必须选择 **armeabi-v7a** 架构版本，arm64-v8a 版本无法运行。

---

## 1. Root / 刷机可行性

**结论：不可行。**

Sony Bravia X75H 没有任何可用的 root 方案，也没有第三方刷机包。
Sony TV 的 bootloader 完全锁死，`adb root` 直接拒绝，XDA 上多个线程均已确认此限制。
本项目所有操作均在普通 ADB shell 权限下完成。

---

## 2. 与 Ansible_X08A 的核心差异

| 功能 | X08A（已 root） | X75H（无 root） |
|------|----------------|----------------|
| 写入 `/system` 分区 | ✅ | ❌ |
| `adb remount` | ✅ | ❌ |
| 推送 APK 到 `/system/app/` | ✅ | ❌ |
| `pm disable-user --user 0` | ✅ | ✅ |
| `pm uninstall --user 0` | ✅ | ✅ |
| `adb install -r` | ✅ | ✅ |
| `settings put` | ✅ | ✅ |
| `cmd package set-home-activity` | ✅ | ✅ |
| 电源优化白名单（需 root） | ✅ | ❌ |

---

## 3. 禁用应用策略说明

本项目全部使用 `pm disable-user --user 0` 而非 `pm uninstall`。

原因：`disable` 随时可通过 `pm enable` 恢复，安全可逆；而在无 root 的普通 shell 下，`disable` 对系统应用的兼容性比 `uninstall` 更可靠。

### 3.1 遥测 / 隐私（最高优先级）

| 包名 | 说明 |
|------|------|
| `tv.samba.ssm` | Samba TV 行为追踪主服务，著名隐私问题应用 |
| `tv.samba.gat` | Samba TV ACR（自动内容识别），识别你在看什么并上报 |
| `com.sony.dtv.watchtvrecommendation` | 监控收视行为并上报 |
| `com.sony.dtv.networkrecommendation` | 网络行为追踪推荐 |
| `com.sony.dtv.irbrecommendation` | 遥控按键习惯追踪 |
| `com.sony.dtv.woprecommendation` | 开机行为追踪推荐 |
| `com.sony.dtv.recommendationservice` | 推荐引擎主服务（聚合上述追踪数据） |
| `com.sony.qrmt` | Sony 远程诊断服务 |
| `com.google.android.feedback` | Google 崩溃/使用数据上报 |

### 3.2 广告 / 推广内容

| 包名 | 说明 |
|------|------|
| `com.google.android.tvrecommendations` | Google TV 主页广告推荐栏 |
| `com.sony.dtv.sonyselect` | Sony Select 精选广告内容 |
| `com.sony.dtv.sonyselect.overlay` | Sony Select 覆盖层 |
| `com.sony.dtv.discovery` | 内容探索推荐（广告驱动） |
| `com.sony.snei.video.hhvu` | Sony 视频推广服务 |
| `com.sony.dtv.bravialifehack` | Bravia Life Hack 广告内容 |

### 3.3 Sony 无用内置功能

| 包名 | 说明 |
|------|------|
| `com.sony.dtv.demo` | 零售演示模式 |
| `com.sony.dtv.demomode` | 演示模式核心服务 |
| `com.sony.dtv.demosupport` | 演示支持 |
| `com.sony.dtv.multiscreendemo` | 多屏演示 |
| `com.sony.dtv.smarthelp` | Smart Help 客服入口 |
| `com.sony.dtv.customersupport` | 客户支持应用 |
| `com.sony.dtv.imanual` | 电子说明书 |
| `com.sony.dtv.eulaviewer` | EULA 弹窗服务（初始化完成后永久无用） |
| `com.sony.dtv.interactive.tv.service` | 互动 TV 平台（HbbTV 相关）⚠️ 见注意事项 |

### 3.4 Google 冗余组件

| 包名 | 说明 |
|------|------|
| `com.google.android.videos` | Google Play 影视 |
| `com.google.android.youtube.tvmusic` | YouTube Music TV 版 |
| `com.google.android.play.games` | Google Play 游戏 |
| `com.google.android.marvin.talkback` | 无障碍语音朗读（TalkBack） |
| `com.google.android.tts` | Google TTS 引擎 |
| `com.google.android.tvtutorials` | Android TV 使用教程 |
| `com.google.android.katniss` | Google 语音搜索助手（禁用后遥控麦克风失效） |

> **⚠️ 注意 `com.sony.dtv.interactive.tv.service`**：
> 部分固件版本下禁用此包会导致系统设置菜单无法打开。
> 若出现此问题，执行 `adb shell pm enable com.sony.dtv.interactive.tv.service` 恢复。

---

## 4. 安装应用清单

### 4.1 应用选型说明

**YouTube 无广告方案**：

- `AdGuard for Android TV` **无法**拦截 YouTube 广告。官方文档明确说明：Android TV 版 AdGuard 无法过滤 HTTPS 流量，因此无法拦截 YouTube 或 Amazon Prime 的广告。
- 正确方案是使用第三方 YouTube 客户端，完全绕过广告投放机制：
  - **NewPipe**：轻量级，无需 Google 账号，完全无广告
  - **SmartTube**：专为 Android TV 大屏和遥控器优化，内置 SponsorBlock，支持登录 Google 账号查看订阅和历史，是电视上看 YouTube 的最佳体验

**SmartTube 安全事件说明**：2025 年 11 月开发者编译机器遭入侵，部分版本（30.43、30.47）被植入恶意代码。版本 30.56 起已完全修复并更换签名。只从官方 GitHub（`github.com/yuliskov/SmartTube`）下载，不从第三方站点获取。

**浏览器**：Firefox (fenix) 是目前 Android 上唯一支持 WebExtension（uBlock Origin 等）的浏览器。虽然非 TV 优化 UI，但遥控器操控体验差是已知局限，暂无更好替代。

**Solid Explorer**：2.8.63 是最后一个提供独立单 APK 的版本。3.x 起改为 XAPK（Bundle + splits），标准 `adb install -r` 无法安装，需 `adb install-multiple` 或专用工具。继续使用 2.8.63 单 APK 版本。

### 4.2 APK 下载地址

> 所有 APK 手动下载后放入 `roles/apps/files/` 目录。

| 应用 | 版本 | 架构 | 下载地址 | 备注 |
|------|------|------|----------|------|
| **NewPipe** | latest | universal | `https://github.com/TeamNewPipe/NewPipe/releases/latest/download/NewPipe.apk` | 固定 URL，永远最新 |
| **SmartTube** | latest stable | armeabi-v7a | `https://github.com/yuliskov/SmartTube/releases/latest/download/SmartTube_stable_armeabi-v7a.apk` | 固定 URL，永远最新 |
| **VLC** | 3.7.0 | armeabi-v7a | `https://get.videolan.org/vlc-android/3.7.0/VLC-Android-3.7.0-armeabi-v7a.apk` | 升级时改 URL 中版本号 |
| **Kodi** | 21.3 Omega | armeabi-v7a | `https://mirrors.kodi.tv/releases/android/arm/kodi-21.3-Omega-armeabi-v7a.apk` | 升级时改 URL 中版本号 |
| **Firefox (fenix)** | 136.x | armeabi-v7a | `https://ftp.mozilla.org/pub/fenix/releases/` 选对应版本下 `fenix-{版本}-armeabi-v7a.apk` | 无固定 latest 链接 |
| **Projectivy Launcher** | 4.68 | universal | APKMirror: `apkmirror.com/apk/spocky/projectivy-launcher-android-tv/` | 闭源，手动下载 |
| **Solid Explorer** | **2.8.63** | armeabi-v7a | APKMirror: `apkmirror.com/apk/neatbytes/solid-explorer-file-manager/solid-explorer-file-manager-2-8-63-release/solid-explorer-file-manager-2-8-63-3-android-apk-download/` | **最后单 APK 版本** |

### 4.3 Kodi 字体

`roles/apps/files/fonts/` 目录下的字体文件部署到：

```
/storage/emulated/0/Android/data/org.xbmc.kodi/files/.kodi/media/Fonts/
```

推送命令（注意末尾的 `.`，推送目录内容而非目录本身）：

```bash
adb push fonts/. /storage/emulated/0/Android/data/org.xbmc.kodi/files/.kodi/media/Fonts/
```

---

## 5. Ansible 自动化部署

### 5.1 前置条件

- 控制节点已安装 `adb` 和 `ansible`
- TV 已开启开发者模式及网络 ADB 调试
- 所有 APK 已按上表手动下载并放入 `roles/apps/files/`

### 5.2 执行部署

```bash
./apply.sh
```

脚本将按以下顺序自动完成操作：

**`roles/system_init`**

1. ADB 连接验证（`connect.yml`）
2. 批量禁用遥测、广告、冗余应用（`clear.yml`）

**`roles/apps`**

1. 安装所有 APK（`install_apks.yml`）
2. 设置 Projectivy 为默认桌面（`launcher.yml`）
3. 部署 Kodi 字体、sources.xml、splash 图（`kodi.yml`）
4. 最终状态验收检查（`status.yml`）

### 5.3 项目文件结构

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

## 6. 后续手动配置

### 6.1 Kodi 首次启动设置

```
Interface → 底部切换 Standard 到 Expert
Interface → Font → 改为 ArialBased
Player → Subtitle → Font → 改为 NotoSC-simibold（或已推送的字体名）
```

### 6.2 Projectivy Launcher 配置

Projectivy 设为默认桌面后，首次启动需手动完成初始化引导。
如需授权悬浮窗等权限：

```bash
adb shell appops set com.spocky.projengmenu SYSTEM_ALERT_WINDOW allow
```

### 6.3 SmartTube 首次配置

SmartTube 内置自动更新检测，有新版本时会在应用内提示。
无需手动维护 APK，确认安装即可。

---

## 7. 故障排除

**问题：禁用 `com.sony.dtv.interactive.tv.service` 后系统设置无法打开。**

```bash
adb shell pm enable com.sony.dtv.interactive.tv.service
```

**问题：Projectivy 设为默认桌面后按 Home 键仍回到 Sony 原生界面。**

```bash
adb shell pm disable-user --user 0 com.google.android.tvlauncher
```

恢复：
```bash
adb shell pm enable com.google.android.tvlauncher
```

**问题：ADB 连接失败，设备离线。**

Android TV 息屏后 ADB Wi-Fi 会静默断开。先唤醒屏幕，再重新执行 `adb connect 192.168.50.220:5555`。

**问题：APK 安装失败，提示存储空间不足。**

先卸载旧版本：

```bash
adb shell pm uninstall <包名>
```

再重新安装。
