from pathlib import Path

def find_videos_without_nfo(directory_path: str):
    path = Path(directory_path)
    # 涵盖绝大部分常见视频格式
    video_extensions = {'.mp4', '.mkv', '.avi', '.mov', '.flv', '.wmv', '.rmvb', '.ts', '.iso', '.m4v', '.mpg', '.mpeg', '.m2ts', '.vob', '.webm'}
    
    # 忽略常见的 NAS 和系统缓存/隐藏文件夹
    ignored_dirs = {'.@__thumb', '@eaDir', '.AppleDouble', '.Trash'}
    
    missing_nfo_videos = []
    total_valid_videos = 0
    
    if not path.exists():
        print(f"路径 '{directory_path}' 不存在。")
        return

    for item in path.rglob('*'):
        # 如果文件路径中包含被忽略的文件夹，则跳过
        if any(part in ignored_dirs for part in item.parts):
            continue
            
        if item.is_file() and item.suffix.lower () in video_extensions:
            total_valid_videos += 1
            # 检查同名的 .nfo (例如: video.mp4 -> video.nfo)
            same_name_nfo = item.with_suffix('.nfo')
            
            # 检查目录级的通用 nfo (TMM 在处理标准电影目录时常用)
            movie_nfo = item.parent / "movie.nfo"
            tvshow_nfo = item.parent / "tvshow.nfo"
            
            # 如果这三种 nfo 都不存在，说明该视频大概率没被 TMM 成功入库
            if not (same_name_nfo.exists() or movie_nfo.exists() or tvshow_nfo.exists()):
                missing_nfo_videos.append(item)
                
    print(f"排查完毕！共扫描到 {total_valid_videos} 个有效的视频文件。")
    print(f"其中有 {len(missing_nfo_videos)} 个未生成 NFO 信息：\n")
    
    # 打印前 30 个未识别文件及其所在的文件夹，方便你定位
    for f in missing_nfo_videos[:30]:
        print(f" ⚠️ {f.name}")
        print(f"    📁 位于: {f.parent}\n")
        
    if len(missing_nfo_videos) > 30:
        print(f"... 还有 {len(missing_nfo_videos) - 30} 个文件未列出。")

# 运行代码：将 "." 替换为你的真实视频目录路径
# find_videos_without_nfo("/你的/视频/路径")
find_videos_without_nfo(".")
