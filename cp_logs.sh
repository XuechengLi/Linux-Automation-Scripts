service微服务自动化部署
#!/bin/bash

# ================= 配置区域 =================
deploy_src="/opt/deploy-application/backend/dkdy-cloud"
ossfs_src="/opt/ossfs/dkdy-cloud"

# 自动获取上个月时间 
target_date=$(date -d "last month" "+%Y%m")
dir_date=$(date -d "last month" "+%Y.%m")

echo "==================== 日志归档启动 ===================="
echo "执行时间: $(date)"
echo "目标归档时间(上月): $dir_date"
echo "源目录: $deploy_src"
echo "--------------------------------------------------"

# 切换工作目录，确保操作在源目录下进行
cd "$deploy_src" || { echo "❌ 严重错误: 无法进入源目录 $deploy_src"; exit 1; }

# 遍历所有 service- 开头的服务
for service_dir in service-* gateway; do
    # 跳过非目录文件
    [ -d "$service_dir" ] || continue

    echo ">>> 正在检查服务: $service_dir"

    # 初始化变量
    port=""
    middle_dir="pord2" 
    case $service_dir in
	service-auth)     port="20100" ;;
        service-channel)  port="21300" ;;
        service-cls)      port="20800" ;;
        service-external) port="21200" ;;
        service-tms)      port="20300" ;;
	gateway)	  port="20000" ;;
        *)
            echo "    ⚠️ 跳过: 未配置服务 $service_dir"
            continue
            ;;
    esac

    parent_path="$ossfs_src/$service_dir/$middle_dir/$port"
    # 这一级是我们要创建的新目录 (月份)
    dest_final_dir="$parent_path/$dir_date"
    # 检查父目录是否存在 
         if [ ! -d "$parent_path" ]; then
         echo "    ❌ [失败] 父目录不存在，跳过创建: $parent_path"
         continue 
     fi

    #创建目录
    # 如果 dest_final_dir 已经存在，mkdir 会报错，正好提醒防止覆盖
    if [ ! -d "$dest_final_dir" ]; then
       mkdir  "$dest_final_dir"
        if [ $? -ne 0 ]; then
             echo "    ❌ [失败] 目录创建失败: $dest_final_dir"
             continue
        fi
        echo "    📂 [创建] 目录成功: $dest_final_dir"
    else
        echo "    📂 [存在] 目录已存在: $dest_final_dir"
    fi

    # 执行复制 (cp)
    # 检查源文件是否存在，避免 cp 报错刷屏
    file_count=$(ls "$service_dir/$port"/run_log.${target_date}*.log 2>/dev/null | wc -l)

    if [ "$file_count" -gt 0 ]; then
        echo "    🔄 正在复制 $file_count 个日志文件..."
        cp -r "$service_dir/$port"/run_log.${target_date}*.log "$dest_final_dir/"
        if [ $? -eq 0 ]; then
            echo "    ✅ [成功] 归档完成"
        else
            echo "    ❌ [失败] 复制过程中发生错误"
        fi
    else
        echo "    ⚠️ [跳过] 源目录未发现 ${target_date} 的日志文件"
    fi
    echo "--------------------------------------------------"
done
echo "==================== 全部执行完毕 ===================="
