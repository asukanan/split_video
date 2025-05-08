# 自用，仅测试Mac，其他系统未测试
- 这是一个简单的小脚本，可以指定的特定大小（如1.9GB）为单位，将视频分割成数段
- 因为是调用的 FFmpeg，所以必须安装 FFmpeg
- 支持一次性添加多个视频，脚本会在原视频同级目录下创建名为"video-name_parts"的文件夹，分割完成后的文件会自动命名并放入此文件夹
- 支持中文路径和中文文件名
## 使用
```
wget https://raw.githubusercontent.com/asukanan/split_video/refs/heads/main/split_video.sh -O ~/.local/bin/split_video.sh
chmod +x ~/.local/bin/split_video.sh
split_video.sh
```
## 停用
```
rm ~/.local/bin/split_video.sh
```
