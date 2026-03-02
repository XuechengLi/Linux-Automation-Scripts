#后端service一键自动化构建部署脚本
#!/bin/bash

# 源码目录
build_base="/opt/builds/backend/dkdy-cloud"
# 部署目录
deploy_base="/opt/deploy-application/backend/dkdy-cloud"
# 本地仓库旧包目录
maven_repo="/opt/maven/maven3.9.9/repository/com/dkdy"

# 拉取最新的 test 分支
cd ${build_base}
git pull
git switch test

# 清空本地仓库旧jar包
rm -rf ${maven_repo}

# 构建
mvn -f ${build_base}/pom.xml  -DskipTests=true  -Dmaven.compile.fork=true  -Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 -T 4C clean
mvn -f ${build_base}/pom.xml  -DskipTests=true  -Dmaven.compile.fork=true  -Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 -T 4C install
mvn -f ${build_base}/pom.xml  -DskipTests=true  -Dmaven.compile.fork=true  -Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 -T 4C package

# 复制到运行目录函数
deploy_service() {
    service_name=$1

    echo "正在复制: ${service_name} ..."
    
    # 创建目录
    mkdir -p ${deploy_base}/${service_name}
    
    # 删除旧jar包
    rm -f ${deploy_base}/${service_name}/${service_name}-1.jar
    
    # 复制新jar包
    cp ${maven_repo}/${service_name}/1/${service_name}-1.jar ${deploy_base}/${service_name}/
    
    echo "完成复制: ${service_name}"
}

# 复制所有服务
deploy_service "service-ai-bailian"
deploy_service "service-aop"
deploy_service "service-auth"
deploy_service "service-channel"
deploy_service "service-cls"
deploy_service "service-cms"
deploy_service "service-cs"
deploy_service "service-dingtalk"
deploy_service "service-exam"
deploy_service "service-external"
deploy_service "service-feign"
deploy_service "service-loc"
deploy_service "service-log"
deploy_service "service-oss"
deploy_service "service-props"
deploy_service "service-sms"
deploy_service "service-test"
deploy_service "service-tms"
deploy_service "service-tool"
deploy_service "service-customer"
deploy_service "gateway"
deploy_service "service-ai-google"
deploy_service "service-task"

# 单独复制网关
# service_name="gateway"
# echo "正在复制: ${service_name}"
# mkdir -p ${deploy_base}/${service_name}
# rm -f ${deploy_base}/${service_name}/${service_name}-1.jar
# cp ${maven_repo}/${service_name}/1/${service_name}-1.jar ${deploy_base}/${service_name}/


echo "所有服务复制完成！"



echo "启动....."ps 
# 先启动 props、dingtalk
sh ${deploy_base}/service-props/restart_20700.sh
sleep 5 
sh ${deploy_base}/service-dingtalk/restart_21100.sh
sleep 5

# 启动其他服务
sh ${deploy_base}/service-auth/restart_20100.sh
sh ${deploy_base}/service-cms/restart_20200.sh
sh ${deploy_base}/service-tms/restart_20300.sh
sh ${deploy_base}/service-cs/restart_20400.sh
sh ${deploy_base}/service-oss/restart_20500.sh
sh ${deploy_base}/service-sms/restart_20600.sh
sh ${deploy_base}/service-cls/restart_20800.sh
sh ${deploy_base}/service-loc/restart_20900.sh
sh ${deploy_base}/service-tool/restart_21000.sh
sh ${deploy_base}/service-external/restart_21200.sh
sh ${deploy_base}/service-channel/restart_21300.sh
sh ${deploy_base}/service-exam/restart_21400.sh
sh ${deploy_base}/service-log/restart_21500.sh
sh ${deploy_base}/service-ai-bailian/restart_21600.sh
sh ${deploy_base}/service-customer/restart_21700.sh
sh ${deploy_base}/service-ai-google/restart_21800.sh
sh ${deploy_base}/service-task/restart_21900.sh

# 启动网关
sh ${deploy_base}/gateway/restart_20000.sh


echo "全部执行完成！"
exit 0
