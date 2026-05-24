###############################################################
# Install  G7BTS 
###############################################################
Bluetooth Pairing
Ensure the remote control is charged.
Press and hold the OK button and the IR button simultaneously for a few seconds. The green LED indicator on the remote will flash quickly, indicating it has entered pairing mode.
On your target device (e.g., Smart TV, Android TV Box, PC), navigate to the Bluetooth settings.
Search for available Bluetooth devices and select "G7BTS" from the list.
Once connected, the green LED on the remote will turn off.

Note: If you wish to use the remote with a different device, you must first unpair "G7BTS" from the currently connected device.



###############################################################
# Install  launcher
###############################################################
# Command
```
adb connect 192.168.50.220

adb install ProjectivyLauncher-4.68-c82-xda-release.apk

# 1. 确认 Projectivy 是否安装成功
adb shell pm list packages | grep spocky

# 2. 检查当前系统生效的桌面（诊断用，看看到底是谁在占领 Home）
adb shell cmd package resolve-activity --brief -c android.intent.category.HOME -a android.intent.action.MAIN

# 3. 手动强制启动 Projectivy 界面
adb shell am start -n com.spocky.projengmenu/com.spocky.projengmenu.ui.home.MainActivity

# 4. 确保 Projectivy 组件处于启用状态
adb shell pm enable com.spocky.projengmenu

adb shell cmd package set-home-activity com.spocky.projengmenu/com.spocky.projengmenu.ui.home.MainActivity

```

# Set Default App
+ Settings--App and Notice--Default App--Main Screen App
+ adb
```
adb shell cmd package set-home-activity bitpit.launcher/.ui.HomeActivity
```


###############################################################
# Android TV default launcher 
###############################################################
Ref: [https://gitlab.com/flauncher/flauncher]

# Disable
如果执行完上述指令按主页键还是跳回 Sony 原生界面，那说明 Sony 的 launcherx 优先级太高，你可以执行下面命令来彻底物理隔离它。
```
adb shell pm disable-user --user 0 com.google.android.tvlauncher
```

# Enable
```
adb shell pm enable com.google.android.tvlauncher
```


###############################################################
# Android TV Settings
###############################################################
+ Method 1:
Settings Buttion
+ Method 2:
```
adb shell am start -n com.android.tv.settings/.MainSettings 
```



###############################################################
# Static Wallpaper [3840 x 2160]
###############################################################
1. Install Simple-Gallery 
URL:[https://github.com/SimpleMobileTools/Simple-Gallery/releases/download/6.28.1/gallery-396-foss-release.apk]
adb install gallery-396-foss-release.apk

2. Copy
```
adb push Marvin.jpg /sdcard/Pictures

adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///storage/emulated/0/Pictures
```

3. Using Simple-Gallery as default gallery app to setup the wallpaper


+ Test
```
adb shell am start -a android.intent.action.SET_WALLPAPER
adb shell am start -a android.intent.action.ATTACH_DATA -d file:///storage/emulated/0/Pictures/Marvin.jpg -t image/jpeg
```

###############################################################
# Dynamic Wallpaper
###############################################################
```
adb install net.nurik.roman.muzei_340504_apps.evozi.com.apk
```

###############################################################
# Other apps
###############################################################
```
adb install NewPipe_v0.28.3.apk
adb install pl.solidexplorer2_2.8.41-200282_minAPI19(armeabi-v7a)(nodpi)_apkmirror.com.apk
adb install org.mozilla.firefox_135_apps.evozi.com.apk
```



###############################################################
# Restart
###############################################################
Press and hold "Power" for several seconds, will show "Power off" and "Restart" 
