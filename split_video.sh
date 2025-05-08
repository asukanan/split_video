#!/bin/bash

if ! command -v ffmpeg &>/dev/null || ! command -v ffprobe &>/dev/null; then
  echo "请先安装 ffmpeg 和 ffprobe"
  exit 1
fi

echo "🎬 欢迎使用 视频分割小工具"
echo "📥 请将视频文件拖入终端，输入完成后按回车确认（可多选）："
IFS= read -r input_line

# 清洗路径数组
inputs=()
while IFS= read -r -d '' path; do
  clean_path="${path%\"}"
  clean_path="${clean_path#\"}"
  clean_path="${clean_path%\'}"
  clean_path="${clean_path#\'}"
  inputs+=("$clean_path")
done < <(printf "%s" "$input_line" | xargs -0 -n1 echo | while read -r line; do printf "%s\0" "$line"; done)

# 处理每个视频文件
for input in "${inputs[@]}"; do
  if [ ! -f "$input" ]; then
    echo "❗ 文件不存在：$input，跳过..."
    continue
  fi

  echo ""
  echo "🚀 正在处理：$input"
  filename=$(basename "$input")
  basename_no_ext="${filename%.*}"
  dir=$(dirname "$input")
  output_dir="$dir/${basename_no_ext}_parts"
  mkdir -p "$output_dir"

  # 获取视频文件的总体大小
  filesize=$(stat -f%z "$input")

  # 将字节大小转换为可读格式
  filesize_gb=$(echo "scale=2; $filesize / (1024 * 1024 * 1024)" | bc)
  filesize_human=$(echo "$filesize_gb GB")

  echo "📋 视频文件大小：$filesize_human"

  # 选择分割大小
  read -p "请输入单个分割片段的最大大小（单位GB，例如 1.9 代表 1.9GB）： " size_gb
  if [ -z "$size_gb" ]; then
    echo "❌ 未输入分割大小，退出。"
    exit 1
  fi
  max_size=$(echo "$size_gb * 1024 * 1024 * 1024" | bc | cut -d'.' -f1)

  echo "👉 将按每个最大 $size_gb GB（即 $max_size 字节）分割"
  echo ""

  duration=$(ffprobe -v error -select_streams v:0 -show_entries format=duration -of csv=p=0 "$input")
  duration_int=$(printf "%.0f" "$duration")
  echo "📋 视频总时长：$duration_int 秒"

  start=0
  part=1
  part_files=()

  total_size=0
  total_parts=$(echo "$filesize / $max_size" | bc)

  # 当前进度初始化
  echo -n "当前进度："
  echo -n "0%"

  while true; do
    output_file="$output_dir/${basename_no_ext}_part${part}"

    # 直接保存为原始格式
    output_file="$output_file.${filename##*.}"

    # 获取分割前的时间戳
    start_time=$(date +%s)

    # 开始分割，隐藏详细输出
    ffmpeg -loglevel quiet -ss "$start" -i "$input" -c copy -fs "$max_size" "$output_file"

    part_files+=("$output_file")

    part_duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 -i "$output_file")
    if [ -z "$part_duration" ]; then
      rm -f "$output_file"
      break
    fi

    start=$(echo "$start + $part_duration" | bc)
    part=$((part+1))

    # 更新已分割的数据量
    part_filesize=$(stat -f%z "$output_file")
    total_size=$((total_size + part_filesize))

    # 计算当前进度
    current_progress=$(echo "scale=2; $total_size / $filesize * 100" | bc)

    # 显示百分比进度
    echo -ne "\r当前进度：$current_progress%"

    # 检查最后片段大小，如果小于最大分割大小，则停止分割
    final_filesize=$(stat -f%z "$output_file")
    if (( final_filesize < max_size )) && [ "$part" -gt 1 ]; then
      break
    fi

    if (( $(echo "$start > $duration" | bc -l) )); then
      echo "✅ 所有分割完成"
      break
    fi
  done

  echo "📂 输出目录：$output_dir"
  for file in "$output_dir"/*; do
    size_human=$(du -h "$file" | cut -f1)
    echo " - $(basename "$file") [$size_human]"
  done

  open "$output_dir"
done

echo ""
echo "🚀 所有任务完成！感谢使用～"
