# 📺 Android TV 高级配置与扩展指南 (ADB 部署篇)

本指南涵盖了第三方蓝牙遥控器配对、桌面替换、壁纸自定义以及常用应用的 ADB 侧载流程。

---

## 1. G7BTS 蓝牙遥控器配对指南

1. **准备工作**：确保 G7BTS 遥控器电量充足。
2. **进入配对模式**：同时长按遥控器上的 `OK` 键和 `IR` 键几秒钟。当遥控器上的绿色 LED 指示灯开始快速闪烁时，说明已进入配对状态。
3. **设备端连接**：在你的目标设备（如智能电视、Android 电视盒子或 PC）上，进入蓝牙设置界面。
4. **配对与确认**：搜索可用的蓝牙设备，在列表中选择 `G7BTS`。连接成功后，遥控器上的绿色 LED 灯将熄灭。
> **注意**：如果需要将该遥控器连接到其他新设备，必须先在当前已连接的设备上取消配对（忽略设备）。

---

## 2. 部署 Projectivy Launcher (第三方桌面)

通过 ADB 安装并强制设置 Projectivy 为默认桌面。

```bash
# 1. 连接电视 (替换为你的电视 IP)
adb connect 192.168.50.220

# 2. 安装 Projectivy Launcher 安装包
adb install ProjectivyLauncher-4.68-c82-xda-release.apk

# 3. 确认是否安装成功 (检查包名)
adb shell pm list packages | grep spocky

# 4. 检查当前系统默认的主屏幕程序 (诊断用)
adb shell cmd package resolve-activity --brief -c android.intent.category.HOME -a android.intent.action.MAIN

# 5. 手动强制启动 Projectivy 界面
adb shell am start -n com.spocky.projengmenu/com.spocky.projengmenu.ui.home.MainActivity

# 6. 确保 Projectivy 组件处于启用状态，并将其设置为系统默认桌面
adb shell pm enable com.spocky.projengmenu
adb shell cmd package set-home-activity com.spocky.projengmenu/com.spocky.projengmenu.ui.home.MainActivity
```

**UI 界面设置默认桌面（替代方法）：**
依次进入 `设置 (Settings)` -> `应用和通知 (App and Notice)` -> `默认应用 (Default App)` -> `主屏幕应用 (Main Screen App)`。

*(注：如果你使用的是其他桌面，如 bitpit，设置默认桌面的命令为：`adb shell cmd package set-home-activity bitpit.launcher/.ui.HomeActivity`)*

---

## 3. 冻结 / 恢复原生桌面 (解决按 Home 键跳转问题)

如果执行完上述步骤后，按主页 (Home) 键依然跳回 Sony 原生界面，说明原生桌面的优先级过高，需要通过 ADB 将其彻底物理隔离（冻结）。

```bash
# 冻结并禁用 Android TV 默认原生桌面
adb shell pm disable-user --user 0 com.google.android.tvlauncher

# 恢复/启用 Android TV 默认原生桌面 (如需还原)
adb shell pm enable com.google.android.tvlauncher
```

---

## 4. 调出 Android TV 原生设置界面

当第三方桌面没有提供设置入口时，可以通过以下方式呼出：
* **方法一**：直接按遥控器上的“设置”实体按键。
* **方法二**：通过 ADB 命令强制拉起原生设置界面：
  ```bash
  adb shell am start -n com.android.tv.settings/.MainSettings 
  ```

---

## 5. 自定义壁纸设置

### 5.1 静态壁纸 (推荐分辨率: 3840 x 2160)
由于 TV 系统通常不带图片浏览器，需借助第三方相册应用来设置壁纸。

```bash
# 1. 安装 Simple-Gallery (简易相册)
adb install gallery-396-foss-release.apk

# 2. 将壁纸图片推送到电视内部存储的 Pictures 目录
adb push Marvin.jpg /sdcard/Pictures

# 3. 触发媒体扫描，让相册能立刻识别到新图片
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///storage/emulated/0/Pictures
```
**后续操作**：在电视上打开 Simple-Gallery，找到推送到本地的图片，通过相册菜单将其设置为壁纸。

*(可选测试命令：可通过 `adb shell am start -a android.intent.action.SET_WALLPAPER` 直接呼出壁纸设置组件)*

### 5.2 动态壁纸
```bash
# 安装 Muzei 动态壁纸应用
adb install net.nurik.roman.muzei_340504_apps.evozi.com.apk
```

---

## 6. 其他常用基础应用侧载 (Sideload)

```bash
# 安装 NewPipe (免广告 YouTube 第三方客户端)
adb install NewPipe_v0.28.3.apk

# 安装 Solid Explorer (强大的文件管理器)
adb install pl.solidexplorer2_2.8.41-200282_minAPI19(armeabi-v7a)(nodpi)_apkmirror.com.apk

# 安装 Firefox 浏览器 (TV 适用版)
adb install org.mozilla.firefox_135_apps.evozi.com.apk
```

---

## 7. 软重启设备

如果遇到系统卡顿或需要使某些底层配置生效：
* 长按遥控器上的 **电源键 (Power)** 几秒钟。
* 在弹出的侧边栏/对话框中，选择 **“重启 (Restart)”**。
