####################################################################################################################
# Chinese Fonts
####################################################################################################################
```
adb push NotoSans-Regular.ttf /sdcard/Android/data/org.xbmc.kodi/files/.kodi/media/Fonts/
adb push NotoSans-Regular.ttf /storage/emulated/0/Android/data/org.xbmc.kodi/files/.kodi/media/Fonts

```

推送完成后，重启 Kodi，进入 Settings -> Player -> Language。在 Font to use for subtitles 这一项里，你就能看到你推送的 NotoSansSC-Bold.ttf 等文


####################################################################################################################
# AENONOXSILVO Addon (Skin)
####################################################################################################################



####################################################################################################################
# Create Your MSIF
####################################################################################################################
To Collect Movie Collection Art Work, need to create MSIF
Ref:[https://kodi.wiki/view/Movie_set_information_folder]

# Add Source: Movies_Sets_Art
1. System-File Manager-Add Source
2. Add network location
3. SMB
Protocal: SMB
Server name: 453BMini
Shared folder: /Media/Video/Movies_Sets_Art
Username: xxxxx
Password: xxxxx


# Set it to source "Movies_Sets_Art"
System-Media-Videos-Library-"Movie set information folder"


# Set Collection Art Work
Navigate to the collection in the Kodi library
From the Context menu select Manage > Choose art


