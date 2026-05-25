from pathlib import Path
import os

def clean_movie_nfo(directory_path: str):
    path = Path(directory_path)
    if not path.exists():
        print(f"路径 '{directory_path}' 不存在。")
        return
        
    count = 0
    print("🔍 正在全盘搜索并清理通用的 movie.nfo 文件 (已排除缓存目录) ...")
    
    # 忽略常见的 NAS 和系统缓存/隐藏文件夹
    ignored_dirs = {'.@__thumb', '@eaDir', '.AppleDouble', '.Trash'}
    
    # rglob 会递归搜索所有子目录 (忽略大小写的问题在 Linux 挂载下通常严格匹配，这里以标准小写为例)
    for item in path.rglob('movie.nfo'):
        # 如果文件路径中包含被忽略的缓存文件夹，则跳过
        if any(part in ignored_dirs for part in item.parts):
            continue
            
        if item.is_file() or item.is_symlink():
            print(f" 🗑️ 正在删除: {item}")
            os.remove(item)
            count += 1
            
    print(f"\n✅ 清理完毕！共删除了 {count} 个 movie.nfo 文件。")

# ⚠️ 请将下面替换为你实际挂载 NAS 电影目录的绝对路径
# 例如: clean_movie_nfo("/home/david/NAS_NFS/Media/Video/Movie")
clean_movie_nfo(".")
