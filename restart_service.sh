#!/bin/bash

MODULE="dkdy-cloud-service-tms"
PORT=20300
DIR="/opt/deploy-application/backend/dkdy-cloud/service-tms"
#/opt/jdk/jdk8.0.442/bin/java
#/opt/jdk/jdk21.0.6/bin/java
JDK="/opt/jdk/jdk21.0.6/bin/java" 
JAR="service-tms-1.jar"
JVMD="-Dserver.port=${PORT}"
JARPATH="${DIR}/${JAR}"
APPEND="--spring.profiles.active=release --server.port=${PORT}"
LOG="run_log.$(date +%Y%m%d).log"

GREPSTR="server.port=${PORT}"

echo "即将重启 ${MODULE}"
echo "当前目录：${DIR}"
cd ${DIR}
PID=`ps -ef | grep -w ${GREPSTR} | grep "java" | awk '{print $2}'`  
if [ "${PID}" == "" ]; then  
    echo "进程不存在或已终止： ${JAR}"
else  
    echo "正在终止进程：${PID}"
    kill -15 ${PID}
fi

echo "启动 ${MODULE} ..."
${JDK} ${JVMD} -jar ${JARPATH} ${APPEND} > /dev/null  2>&1 &
echo "项目日志： ${DIR}/${PORT}/${LOG}"
echo "脚本作者：TIANBOWEN"
