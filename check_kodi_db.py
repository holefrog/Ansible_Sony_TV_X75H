import pymysql
import sys

# ==========================================
# 请在此处修改你的 NAS MySQL/MariaDB 数据库配置
# ==========================================
NAS_HOST = "192.168.1.100"  # NAS 的 IP 地址
NAS_PORT = 3306             # 数据库端口，默认通常是 3306
DB_USER = "kodi"            # Kodi 连接数据库的用户名
DB_PASSWORD = "kodi"        # Kodi 连接数据库的密码
DB_NAME = "MyVideos121"     # 数据库名称 (请确认你 NAS 数据库里最新的 MyVideos 版本)
# ==========================================

def analyze_kodi_db():
    print(f"🔄 正在尝试连接 NAS 数据库 {NAS_HOST}:{NAS_PORT} [{DB_NAME}] ...")
    
    try:
        # 连接到 NAS 数据库
        conn = pymysql.connect(
            host=NAS_HOST,
            port=NAS_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME
        )
        cursor = conn.cursor()
        print("✅ 成功连接到 NAS Kodi 数据库！")
        
        # 1. 统计刮削成功的电影、剧集、单集
        cursor.execute("SELECT count(idMovie) FROM movie")
        movie_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT count(idShow) FROM tvshow")
        tvshow_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT count(idEpisode) FROM episode")
        episode_count = cursor.fetchone()[0]
        
        print("\n📊 Kodi 数据库中的有效条目统计：")
        print(f" 🎬 电影表 (Movies): {movie_count} 部")
        print(f" 📺 剧集表 (TV Shows): {tvshow_count} 部 (共包含 {episode_count} 集)")
        print(f" ➡️  总计媒体条目数: {movie_count + tvshow_count} (对比一下这个是不是你看到的 154)")
        
        # 2. 核心排查：找出“Kodi 扫描了物理文件，但没有生成影视库条目”的游离文件
        # 我们过滤出常见视频后缀，看看哪些不在 movie 和 episode 表里
        query_unscraped = """
        SELECT strFilename, idFile FROM files 
        WHERE (strFilename LIKE '%.mkv' OR strFilename LIKE '%.mp4' OR strFilename LIKE '%.avi' OR strFilename LIKE '%.ts' OR strFilename LIKE '%.iso')
        AND idFile NOT IN (SELECT idFile FROM movie)
        AND idFile NOT IN (SELECT idFile FROM episode)
        """
        cursor.execute(query_unscraped)
        unscraped_files = cursor.fetchall()
        
        print(f"\n⚠️ 惊人发现：有 {len(unscraped_files)} 个视频文件 Kodi 已经记录到了数据库的 files 表里，但拒绝把它们加入媒体库 (movie/episode 表)！")
        if unscraped_files:
            print("以下是前 30 个被 Kodi 抛弃的罪魁祸首文件：")
            for idx, row in enumerate(unscraped_files[:30]):
                print(f"  - [FileID: {row[1]}] {row[0]}")
                
        conn.close()
    except pymysql.MySQLError as e:
        print(f"❌ 数据库连接或查询错误: {e}")
        print("👉 请检查 IP、账号密码是否正确，以及 DB_NAME 是否填写了 Kodi 目前正在使用的最新版本名。")

if __name__ == "__main__":
    analyze_kodi_db()
