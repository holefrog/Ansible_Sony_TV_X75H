# Kodi + MariaDB 集中数据库配置指南

本文档描述如何将 Kodi 的媒体库从本地 SQLite 迁移到 QNAP 上的 MariaDB 容器，
实现配置持久化。TV 重装后 Ansible 推送一个配置文件，Kodi 启动即恢复全部媒体库，
无需重新刮削。

---

## 版本对照表

| Kodi 版本 | 数据库版本 |
|-----------|-----------|
| 21.x Omega | MyVideos131 |
| 22.x Piers | MyVideos139 |

升级 Kodi 大版本时必须处理数据库迁移，见第 5 节。

---

## 第一阶段：QNAP 上建立 MariaDB 容器（一次性手动）

### 1.1 使用 docker-compose 启动容器

使用项目提供的配置文件直接启动 MariaDB：

```bash
docker-compose -f roles/mariadb_init/files/docker-compose.yml up -d
```

### 1.2 关闭强制 SSL（重要）

Kodi Android 版连接 MariaDB 时不支持 SSL 握手，必须关闭强制 SSL，否则连接失败。
由于配置中已将目录映射到宿主机，直接在 QNAP SSH 下执行：

```bash
cat >> /share/CACHEDEV1_DATA/Container_SSD/kodi-mariadb/conf/kodi.cnf << EOF
[mysqld]
skip_ssl
EOF
docker restart kodi-mariadb
```

### 1.3 建立数据库和用户

```bash
docker exec -it kodi-mariadb mysql -u root -p

# 在 MariaDB 提示符下执行：
CREATE DATABASE IF NOT EXISTS kodi_video CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS kodi_music CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON kodi_video.* TO 'kodi'@'%' IDENTIFIED BY '你的kodi密码';
GRANT ALL PRIVILEGES ON kodi_music.* TO 'kodi'@'%' IDENTIFIED BY '你的kodi密码';
FLUSH PRIVILEGES;
EXIT;
```

### 1.4 验证连接

在控制节点（ThinkPad）上测试连通性：

```bash
mysql -h 192.168.50.xxx -u kodi -p kodi_video
# 输入密码后看到 MariaDB 提示符即成功
```

---

## 第二阶段：Ansible 自动推送配置（每次部署自动执行）

### 2.1 模板文件

`roles/apps/files/kodi/advancedsettings.xml.j2`：

```xml
<advancedsettings>
    <videodatabase>
        <type>mysql</type>
        <host>{{ mariadb_host }}</host>
        <port>3306</port>
        <user>{{ mariadb_user }}</user>
        <pass>{{ mariadb_pass }}</pass>
        <name>kodi_video</name>
    </videodatabase>
    <musicdatabase>
        <type>mysql</type>
        <host>{{ mariadb_host }}</host>
        <port>3306</port>
        <user>{{ mariadb_user }}</user>
        <pass>{{ mariadb_pass }}</pass>
        <name>kodi_music</name>
    </musicdatabase>
</advancedsettings>
```

### 2.2 变量定义

`site.yml` 的 `vars` 段加入：

```yaml
vars:
  mariadb_host: "192.168.50.xxx"   # QNAP IP
  mariadb_user: "kodi"
  mariadb_pass: "你的kodi密码"      # 或用 ansible-vault 加密
```

### 2.3 kodi.yml 中的推送任务

Ansible 先在控制节点渲染模板，再用 ADB 推送：

```yaml
- name: 渲染 advancedsettings.xml 模板
  delegate_to: localhost
  ansible.builtin.template:
    src: "{{ role_path }}/files/kodi/advancedsettings.xml.j2"
    dest: "/tmp/advancedsettings.xml"

- name: 推送 advancedsettings.xml 到 Kodi userdata
  delegate_to: localhost
  ansible.builtin.command: >
    {{ adb_cmd }} push /tmp/advancedsettings.xml
    /storage/emulated/0/Android/data/org.xbmc.kodi/files/.kodi/userdata/advancedsettings.xml
```

> **注意**：`ansible.builtin.template` 本地渲染文件，不通过 ADB，所以 `delegate_to: localhost`
> 是正确的。渲染到 `/tmp/` 再 `adb push` 是目前 Ansible + ADB 组合下最干净的方式。

---

## 第三阶段：Kodi 首次配置（一次性手动，之后永久无需重复）

### 3.1 启动 Kodi，确认连接 MariaDB

Kodi 启动后会自动在 MariaDB 里建立 `MyVideos131` 和 `MyMusic83` 数据库，建表完成。

验证方法（在控制节点）：

```bash
mysql -h 192.168.50.xxx -u kodi -p
SHOW DATABASES;
# 应看到 MyVideos131
```

### 3.2 添加媒体源并设置内容类型

在 Kodi 界面：

1. 首页 → Videos → Files → Add videos
2. Browse → 输入 NFS 路径，例如：`nfs://192.168.50.210/Media/Video/Movie/`
3. 给源命名（如"电影"），确定
4. **Set content** → This directory contains → **Movies**
5. 选择刮削器：**The Movie Database (TMDB)**
6. 确定 → **Yes**（刷新所有项目）
7. 等待右上角进度条完成

对每个媒体源重复上述步骤（剧集选 TV Shows，刮削器选 TVDB 或 TMDB）。

> **⚠️ 重要提醒：从本地库迁移到 NAS 集中库的必做步骤**
> 即使你之前在本地已经刮削过，且所有文件夹中都已经包含了 `.nfo` 文件和海报，
> **在连接到全新空的 MariaDB 后，你也必须重新添加源并执行一次刮削！**
> 否则数据库为空，Kodi 首页的“电影”或“剧集”入口将无法生成海报墙，点击后只能看到普通的文件夹目录。
> *(注：由于你文件夹中已有 `.nfo` 等本地元数据，这次“重新刮削”会优先极速读取本地文件，无需漫长的重新联网下载过程。)*
>
> **这是唯一一次手动操作。** 刮削完成后所有数据存入 MariaDB。
> TV 重装后 Ansible 推送 advancedsettings.xml，Kodi 启动直接读取已有的媒体库。

### 3.3 验证媒体库已写入 MariaDB

```bash
mysql -h 192.168.50.xxx -u kodi -p MyVideos131

SELECT strPath, strContent, strScraper
FROM path
WHERE strContent != '' AND strContent IS NOT NULL
ORDER BY strPath;
```

输出应包含你的 NFS 路径，以及对应的 `strContent`（movies/tvshows）和 `strScraper`（metadata.themoviedb.org 等）。

---

## 第四阶段：日常备份（可选但建议）

MariaDB 数据在 QNAP 的 `/share/Container/kodi-mariadb/data/` 目录下持久化，
QNAP 本身的快照和备份机制已经覆盖。

如需额外 SQL 备份：

```bash
docker exec kodi-mariadb mysqldump -u kodi -p你的kodi密码 \
  --databases MyVideos131 kodi_video kodi_music \
  > kodi_db_backup_$(date +%Y%m%d).sql
```

---

## 第五阶段：Kodi 版本升级处理

### 5.1 升级流程

升级前必须先备份：

```bash
docker exec kodi-mariadb mysqldump -u root -p \
  --all-databases > kodi_full_backup_before_upgrade.sql
```

升级步骤：
1. 在 TV 上通过 Ansible 或手动安装新版 Kodi APK
2. 启动 Kodi，它会自动将 `MyVideos131` 迁移到新版本（如 `MyVideos139`）
3. 迁移完成后旧数据库（`MyVideos131`）会保留，可手动删除

```bash
mysql -h 192.168.50.xxx -u root -p
DROP DATABASE MyVideos131;
```

### 5.2 迁移失败处理

如果升级后 Kodi 无法启动或媒体库消失：

```bash
# 恢复备份
mysql -h 192.168.50.xxx -u root -p < kodi_full_backup_before_upgrade.sql
```

然后降回旧版 Kodi APK，查明原因后再重试。

---

## 故障排除

**Kodi 启动后媒体库为空，但 MariaDB 里有数据**

通常是网络问题：Kodi 在网络就绪前就尝试连接 MariaDB 失败，然后回退到空库状态。
重启 Kodi（不是重启 TV）通常可解决。

**连接被拒绝（Connection refused）**

检查 QNAP 防火墙是否放行了 3306 端口，以及 MariaDB 容器是否在运行：

```bash
docker ps | grep kodi-mariadb
```

**SSL 握手错误**

确认 `skip_ssl` 已加入 MariaDB 配置，且容器已重启。

**Kodi 日志位置（用于排查连接问题）**

```bash
adb -s 192.168.50.220:5555 pull \
  /storage/emulated/0/Android/data/org.xbmc.kodi/files/.kodi/temp/kodi.log \
  ./kodi.log
```

查找关键字：`Unable to open database` 或 `SQL:`。
