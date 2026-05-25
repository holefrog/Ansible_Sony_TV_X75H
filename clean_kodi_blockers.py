from pathlib import Path
import os

def clean_blockers(directory_path: str):
    path = Path(directory_path)
    if not path.exists():
        print(f"路径 '{directory_path}' 不存在。")
        return
        
    count = 0
    print("🔍 正在全盘搜索 Kodi 屏蔽文件 (.nomedia) ...")
    
    # rglob 会递归搜索所有子目录
    for item in path.rglob('.nomedia'):
        if item.is_file() or item.is_symlink():
            print(f" 🗑️ 发现并击碎屏蔽墙: {item}")
            os.remove(item)
            count += 1
            
    print(f"\n✅ 清理完毕！共干掉了 {count} 个导致 Kodi 失明的 .nomedia 文件。")

# ⚠️ 请将 "." 替换为你的 ThinkPad 挂载 NAS 电影目录的绝对路径，例如 "/mnt/nas/Media/Video/Movie/"
# 如果你在 NAS 所在的根目录运行，保留 "." 即可
clean_blockers(".")
