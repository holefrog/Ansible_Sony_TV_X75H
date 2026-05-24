# 使用 Windows 版本 Raspberry Pi Imager 刷系统时，可以用软件自带的配置功能定义用户、密码、WIFI。。。。。


# HDMI连接
## TV没有输出
## 解决方法
镜像制作完成后，用电脑打开SD卡根目录的config.txt,先备份一下，然后修改以下：
hdmi_force_hotplug = 1
hdmi_group = 1
hdmi_mode = 16



# 4k下60帧的刷新率
0. Sony TV 设置中，把输入的HDMI模式由Standard改为Enhanced，才能接受60HZ信号。

1. 在\boot\config.txt找到最后一行添加
```
hdmi_enable_4kp60=1
```
保存退出, 重启


2. 重启之后打开首选项-main menu editor, 点击左侧列最后的首选项, 右侧列找到显示器设置, 打勾选中, 点确定。

3. 打开首选项-显示器设置, 将刷新频率改为60, 点击应用, 点击确定



# 蓝牙键盘、鼠标
树莓派初始化第一步(Next)时，键盘先进入配对模式，树莓派自动连接。



# 用户
david/Sz28DxAB



# 没有声音
## 配置

```
sudo raspi-config
```
进入树莓派配置界面，找到Audio。
Choose the audio output: 1 MAI PCM i2s-hifi-0

```
sudo reboot
```


## VLC
VLC中Audio-Audio Device, 选internal HDMI





# 软件
```
sudo apt install firefox-esr
sudo apt install doublecmd-qt
```

