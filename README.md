# Ansible_Sony_TV_X75H

本项目基于 Ansible 自动化工具，对 Sony Bravia X75H Android TV 进行净化改造。
包含禁用预装遥测/广告/冗余应用、安装第三方应用、配置 Kodi（含 MariaDB 集中数据库）及自定义桌面启动器的完整流程。

---

## 0. 目标设备规格

| 参数 | 规格 |
|------|------|
| 型号 | Sony Bravia KD-X75H |
| 操作系统 | Android TV 10 / 11 |
| 内核架构 | armv7l（32-bit，`uname -a` 确认） |
| ADB 权限 | 普通 shell，无 root，无法写入 `/system` |
| ADB 连接 | Wi-Fi，IP `192.168.50.220`，端口 `5555` |

> **架构说明**：Sony 出厂系统为 32-bit 内核，所有 APK 必须选择 **armeabi-v7a** 架构版本。
> **Root 说明**：Sony Bravia X75H bootloader 完全锁死，无任何可用 root 方案。

---

## 1. 项目文件结构

```
Ansible_Sony_TV_X75H/
├── site.yml                          # TV 部署主入口
├── apply.sh                          # 执行 site.yml
├── init_project.sh                   # 初始化目录结构（新机器用）
├── backup_kodi.sh                    # 备份 Kodi 配置到本地
├── group_vars/
│   └── all.yml                       # 所有共享变量（TV IP、MariaDB、Kodi 路径）
├── roles/
│   ├── system_init/
│   │   ├── defaults/
│   │   │   └── main.yml              # 四类应用禁用列表
│   │   └── tasks/
│   │       ├── main.yml
│   │       ├── connect.yml           # ADB 连接与在线验证
│   │       └── clear.yml             # pm disable-user 批量禁用
│   ├── apps/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── install_apks.yml      # adb install -r 安装 APK
│   │   │   ├── permissions.yml       # Android 11 存储权限授予
│   │   │   ├── launcher.yml          # Projectivy 设为默认桌面
│   │   │   ├── kodi.yml              # Kodi 配置文件部署
│   │   │   └── status.yml            # 最终验收检查
│   │   └── files/
│   │       ├── kodi/
│   │       │   ├── advancedsettings.xml.j2   # Jinja2 模板（含 MariaDB 连接）
│   │       │   ├── sources.xml               # NFS 媒体源路径
│   │       │   ├── guisettings.xml           # GUI 设置（含字体，从设备备份）
│   │       │   └── splash.jpg                # 可选启动画面
│   │       ├── fonts/                        # Kodi 中文字体
│   │       └── addons/                       # Kodi addon 安装包（Aeon 皮肤及依赖）
│
> 注意：`skin.aeon.nox.silvo` 皮肤已改为手动安装。
> 本项目不再自动部署 Aeon 皮肤包。
> 如果要启用 Aeon，请手动将 `skin.aeon.nox.silvo` 放到 `{{ kodi_data }}/addons/` 或通过 Kodi 插件管理进行安装，并在 Kodi 中设置为默认皮肤。
```

---

## 2. 前置条件

- 控制节点（ThinkPad）已安装 `adb`、`ansible`、`python3-pymysql`
- TV 已开启开发者模式及网络 ADB 调试
- **核心依赖**：QNAP 基础设施层已部署完毕，且本地存在 `~/.config/homelab/mariadb_config.yml` 凭证文件（由 `Ansible_QNAP` 自动生成）
- 所有 APK 已手动下载并放入 `roles/apps/files/`
- 所有 APK 已手动下载并放入 `roles/apps/files/`

安装 PyMySQL（Ansible MySQL 模块依赖）：

```bash
pip install PyMySQL --break-system-packages
```

---

## 3. 快速开始

### 3.1 首次完整部署流程

> **注意**：本剧本不再拥有数据库密码！密码由外部文件 `~/.config/homelab/mariadb_config.yml` 动态注入。

```
第一步：前往 Ansible_QNAP 项目运行 ./apply.sh 部署 MariaDB 容器，并生成凭证
第二步：返回本项目，运行 ./apply.sh  ← 自动读取凭证，并部署 TV（含推送 advancedsettings.xml）
第三步：等待 Kodi 自动启动并完成首次建库（MyVideos131），由于我们给了足量的等待时间，Kodi 能够从容建表
第四步：Ansible 会继续连接 MariaDB 验证库是否就绪，并写入媒体路径绑定关系
第五步：Kodi 扫描媒体           ← 读取 NFO 写入 MariaDB，完成
```

### 3.2 TV 重装后（MariaDB 已有数据）

```bash
./apply.sh
```

Kodi 启动直接连 MariaDB，媒体库全部恢复，无需任何手动操作。

---

## 4. APK 清单

> 所有 APK 手动下载后放入 `roles/apps/files/`，全部 armeabi-v7a 架构。

### 应用选型说明

**YouTube 无广告**：AdGuard for Android TV 官方明确说明无法拦截 YouTube 广告（HTTPS 流量无法过滤）。正确方案是使用第三方客户端绕过广告机制：
- **NewPipe**：轻量，无需账号，完全无广告
- **SmartTube**：专为 Android TV 遥控器优化，内置 SponsorBlock，支持 Google 账号

> **SmartTube 安全事件**：2025 年 11 月部分版本（30.43、30.47）被植入恶意代码，30.56 起已修复。只从官方 GitHub `github.com/yuliskov/SmartTube` 下载。

**浏览器**：Firefox (fenix) 是目前唯一支持 WebExtension（uBlock Origin 等）的 Android 浏览器，遥控器操控体验较差但无更好替代。

**Solid Explorer**：**2.8.63 是最后一个提供独立单 APK 的版本**，3.x 改为 XAPK Bundle，`adb install -r` 无法安装。

### 下载地址

| 应用 | 架构 | 下载 |
|------|------|------|
| **NewPipe** | universal | `https://github.com/TeamNewPipe/NewPipe/releases/latest/download/NewPipe.apk` |
| **SmartTube** | armeabi-v7a | `https://github.com/yuliskov/SmartTube/releases/latest/download/SmartTube_stable_armeabi-v7a.apk` |
| **VLC** | armeabi-v7a | `https://get.videolan.org/vlc-android/3.7.0/VLC-Android-3.7.0-armeabi-v7a.apk` |
| **Kodi** | armeabi-v7a | `https://mirrors.kodi.tv/releases/android/arm/kodi-21.3-Omega-armeabi-v7a.apk` |
| **Firefox (fenix)** | armeabi-v7a | `https://ftp.mozilla.org/pub/fenix/releases/` 选版本下 `fenix-{版本}-armeabi-v7a.apk` |
| **Projectivy Launcher** | universal | APKMirror: `apkmirror.com/apk/spocky/projectivy-launcher-android-tv/` |
| **Solid Explorer** | armeabi-v7a | APKMirror: `apkmirror.com/apk/neatbytes/solid-explorer-file-manager/solid-explorer-file-manager-2-8-63-release/` **（最后单 APK 版，勿升级至 3.x）** |

---

## 5. 跨项目解耦与 MariaDB 容器（由 Ansible_QNAP 管理）

**重要更新**：为了贯彻“微服务解耦”的架构思想，本 TV 项目现在**完全作为一个纯客户端 (Consumer)**。

关于 MariaDB 的所有“脏活累活”（包括 docker-compose 启动容器、创建数据库用户、关闭 SSL、修复挂载权限等）已经**全部迁移到专门的基础设施项目 Ansible_QNAP** 中实现。

**协同机制：**
1. 在 `Ansible_QNAP` 部署完成时，它会在你的控制节点自动生成文件 `~/.config/homelab/mariadb_config.yml`。
2. 当你运行本项目的 `site.yml` 时，它会第一时间 `include_vars` 这个凭证文件。
3. 随后，本项目通过自带的 `kodi.yml` 生成连接 MariaDB 的 `advancedsettings.xml` 并推送到 TV 端。
4. 本项目还包含了一个更长、更健壮的“等待机制”，确保 TV 端的 Kodi 在首次启动后有充足的时间（>20秒）自发创建 `MyVideos131` 库。

在运行本 TV 部署脚本前，请务必先确认 QNAP 项目部署成功，并生成了有效的凭证。若凭证不存在或 3306 端口无法连通，部署将被自动阻断。

### 5.3 版本升级说明

| Kodi 版本 | 数据库版本 |
|-----------|-----------|
| 21.x Omega | MyVideos131 |
| 22.x Piers | MyVideos139 |

升级 Kodi 大版本前必须先备份数据库，升级后 Kodi 自动迁移，旧库可手动删除。
详见 `KODI.md` 第 5 节。

---

## 6. 禁用应用列表

全部使用 `pm disable-user --user 0`，可随时通过 `pm enable <包名>` 恢复。
完整列表见 `roles/system_init/defaults/main.yml`，分四类：

- **遥测 / 隐私**：Samba TV ACR、Sony 追踪服务、Google 上报
- **广告 / 推广**：Sony Select、Google TV 推荐栏
- **Sony 无用功能**：演示模式、客服入口、EULA 弹窗等
- **Google 冗余**：YouTube Music、TTS、语音搜索等

> ⚠️ `com.sony.dtv.interactive.tv.service`：部分固件禁用后系统设置无法打开，出现时执行 `adb shell pm enable com.sony.dtv.interactive.tv.service` 恢复。

---

## 7. Kodi 配置

完整的 Kodi + MariaDB 配置说明见 `KODI.md`，包含：

- MariaDB 容器初始化
- `advancedsettings.xml` 模板说明
- 媒体路径与内容类型绑定（`site.yml` 自动写入）
- Movie Set 图片目录配置
- 字体与皮肤设置备份方法
- Kodi 版本升级处理流程

---

## 8. 备份

### Kodi 配置备份

```bash
./backup_kodi.sh
```

备份内容：`userdata/`（含数据库、addon_data、guisettings）、`addons/`（皮肤本体）、`Fonts/`。
备份文件同步到 `roles/apps/files/kodi/`，供下次部署自动恢复。

### Projectivy Launcher 备份

```bash
adb -s 192.168.50.220:5555 pull \
  /storage/emulated/0/Android/data/com.spocky.projengmenu/ \
  ./roles/apps/files/projectivy_backup/
```

---

## 9. 故障排除

**禁用 `com.sony.dtv.interactive.tv.service` 后系统设置无法打开**
```bash
adb shell pm enable com.sony.dtv.interactive.tv.service
```

**按 Home 键仍回到 Sony 原生界面**
```bash
adb shell pm disable-user --user 0 com.google.android.tvlauncher
```

**ADB 连接失败 / 设备离线**
Android TV 息屏后 ADB Wi-Fi 静默断开，先唤醒屏幕再重连：
```bash
adb connect 192.168.50.220:5555
```

**Solid Explorer 无法获取存储权限（Android 11）**
Ansible 部署时 `permissions.yml` 已自动处理，手动执行：
```bash
adb shell appops set --uid pl.solidexplorer2 MANAGE_EXTERNAL_STORAGE allow
```

**APK 安装失败，提示空间不足**
```bash
adb shell pm uninstall <包名>
# 再重新执行 apply.sh
```

**Kodi 启动后媒体库为空**
通常是网络就绪前连接 MariaDB 失败，重启 Kodi（不需要重启 TV）即可。
