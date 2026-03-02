#service微服务日志迁移后自动化删除服务器的日志文件并检查是否删除成功
#!/bin/bash
# ================= 配置区域 =================
ossfs_src="/opt/ossfs/dkdy-cloud"
deploy_src="/opt/deploy-application/backend/dkdy-cloud"

echo "==================== 日志清理启动 ===================="
cd $deploy_src || { echo "❌ 严重错误: 无法进入源目录 $deploy_src"; exit 1; }

# 自动获取上个月时间
dir_date=$(date -d "last month" "+%Y.%m")
target_date=$(date -d "last month" "+%Y%m")
port=""
middle_dir="pord2"
for service_dir in service-* gateway; do
	[ -d "$service_dir" ] || continue	
	echo ">>> 正在检查服务: $service_dir"
	case $service_dir in
		service-auth)     port="20100" ;;
                service-channel)  port="21300" ;;
                service-cls)      port="20800" ;;
                service-external) port="21200" ;;
                service-tms)      port="20300" ;;
				gateway)	      port="20000" ;;
		*)
			echo "    ⚠️ 跳过: 未配置端口映射的服务 $service_dir"
			continue
			;;
	esac
	#统计ossfs路径下上月日志数量
	parent_path="$ossfs_src/$service_dir/$middle_dir/$port"
	dest_final_dir="$parent_path/$dir_date/"
	#统计微服务下的上月日志数量
	deploy_service_dir="$deploy_src/$service_dir/$port/run_log.$target_date"
	#判断ossfs目录下是否备份了上月日志文件
	list1=$(ls  "$dest_final_dir" 2>/dev/null | xargs -n 5 echo)
	list2=$(find  "$deploy_service_dir"* -maxdepth 1 -type f -printf "%f\n" 2>/dev/null  | xargs -n 4 )
	sum1=$(ls  "$dest_final_dir" 2>/dev/null | wc -l)
	sum2=$(find  "$deploy_service_dir"* -maxdepth 1 -type f -printf "%f\n" 2>/dev/null  | wc -l)
	if [ "$sum1" -eq "$sum2"  ]; then
		echo ">>> "$service_dir"服务日志已备份: "
		echo "$dest_final_dir"
		echo "$list1"
		echo "-------------------------------------------------------------------"
		echo "-#-----------删除确认-----------#-"
		echo -e ">>>是否要删除 ${service_dir} 服务下的上月日志？\n $(echo "$list2")\n请输入服务名称 ${service_dir} 进行确认:" 
		read -r delete
		if [ "$delete" == "$service_dir" ]; then
			rm -f "$deploy_service_dir"*
			echo "    ✅ 已删除 ${service_dir} 服务下的上月日志文件"
		else
			echo "    ❌ 输入服务名称错误，跳过删除操作"
			continue
		fi
	else
		echo ">>> "$service_dir"服务日志备份情况: "
		echo ">>> ${service_dir}服务目录日志文件数量: $sum2"
		echo "$dest_final_dir"
		
		echo "$list2"
		echo "-----------------------------------------------------------------------------------------------------------"
		echo ">>> ${service_dir}备份目录日志文件数量: $sum1"
		echo "$dest_final_dir"
		echo "$list1"  
		
	fi
done
