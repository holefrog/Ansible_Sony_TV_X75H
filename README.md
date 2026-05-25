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
├── site.yml                          # TV 部署（日常使用）
├── site_mariadb.yml                  # MariaDB 初始化（只跑一次）
├── apply.sh                          # 执行 site.yml
├── apply_mariadb.sh                  # 执行 site_mariadb.yml
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
│   │       └── fonts/                        # Kodi 中文字体
│   └── mariadb_init/
│       └── tasks/
│           ├── main.yml
│           ├── user.yml              # 创建 kodi 用户并授权
│           └── paths.yml             # 写入媒体路径与刮削器绑定
```

---

## 2. 前置条件

- 控制节点（ThinkPad）已安装 `adb`、`ansible`、`python3-pymysql`
- TV 已开启开发者模式及网络 ADB 调试
- QNAP 上 `kodi-mariadb` 容器已运行（见第 5 节）
- 所有 APK 已手动下载并放入 `roles/apps/files/`

安装 PyMySQL（Ansible MySQL 模块依赖）：

```bash
pip install PyMySQL --break-system-packages
```

---

## 3. 快速开始

### 3.1 首次完整部署流程

```
第一步：QNAP 启动 MariaDB 容器
第二步：./apply_mariadb.sh     ← 创建 kodi 用户和权限
第三步：./apply.sh             ← 部署 TV（含推送 advancedsettings.xml）
第四步：TV 上启动 Kodi          ← 等待 Kodi 自动建库（MyVideos131）
第五步：./apply_mariadb.sh     ← 写入媒体路径绑定关系
第六步：Kodi 扫描媒体           ← 读取 NFO 写入 MariaDB，完成
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

## 5. MariaDB 容器设置

### 5.1 docker-compose

使用项目目录下 `roles/mariadb_init/files/docker-compose.yml`，在 QNAP Container Station 中创建应用程序。
或 SSH 进 QNAP 执行：

```bash
docker-compose -f roles/mariadb_init/files/docker-compose.yml up -d
```

### 5.2 关闭强制 SSL（必须）

Kodi Android 版不支持 SSL 握手，不关闭会导致连接失败：

```bash
docker exec -it kodi-mariadb bash
cat >> /etc/mysql/conf.d/kodi.cnf << EOF
[mysqld]
skip_ssl
EOF
exit
docker restart kodi-mariadb
```

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
- 媒体路径与内容类型绑定（`apply_mariadb.sh` 自动写入）
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
