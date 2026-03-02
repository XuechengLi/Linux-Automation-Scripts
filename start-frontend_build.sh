#!/bin/bash

# --- 脚本配置 ---
BASE_DIR="/opt/builds/frontend"

# 注意：请确保这里的列表顺序和项目代号与实际目录名保持一致
PROJECTS=(
    "web-channel"
    "web-consumer"
    "web-partner"
    "web-recruit-admin"
    "web-tms"
    "web-yzsys"
    "web-delivery"
    "web-counselor-system"
    "web-aiAdvisor"
)
# --- 函数定义 ---

# 显示项目列表
function list_projects() {
    echo ""
    echo "========================================="
    echo "🎯 请选择要拉取并启动的项目 (DEV:TEST 模式)"
    echo "========================================="
    for i in "${!PROJECTS[@]}"; do
        # 索引从 1 开始显示
        index=$((i + 1))
        echo "  $index: ${PROJECTS[$i]}"
    done
    echo "-----------------------------------------"
}

# 核心执行函数
function execute_dev_start() {
    list_projects

    read -p "请输入对应的编号 (1-$((${#PROJECTS[@]}))): " SELECTION

    # 验证输入
    if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#PROJECTS[@]}" ]; then
        echo "❌ 无效的编号。请输入 1 到 $((${#PROJECTS[@]})) 之间的数字。"
        return 1
    fi

    # 计算数组索引 (输入编号 - 1)
    INDEX=$((SELECTION - 1))
    PROJECT_NAME="${PROJECTS[$INDEX]}"
    PROJECT_PATH="$BASE_DIR/$PROJECT_NAME"

    echo ""
    echo "🚀 正在处理项目: $PROJECT_NAME (位于 $PROJECT_PATH)"
    echo "-----------------------------------------"
    if [ "$PROJECT_NAME" == "web-recruit-admin" ]; then
        NODE_V14_PATH="/opt/node-v14.21.3-linux-x64/bin"
        # 临时将 Node 14 添加到 PATH 最前面，确保后续的 npm/node 命令使用此版本
        export PATH="$NODE_V14_PATH:$PATH"
        echo "?? 注意：项目 $PROJECT_NAME 需要 Node 14。已临时切换 PATH 到 $NODE_V14_PATH"

    else
        # 其他项目（使用全局配置中的 Node 版本，如 Node 22）
        echo "?? 使用全局 Node 环境 (假设为 Node 22)。"
    fi
    # 验证当前使用的 Node/npm 版本
    echo "?? 验证版本: Node $(node --version), npm $(npm --version)"
    # ----------------------------------------------------
       # 检查目录是否存在
    if [ ! -d "$PROJECT_PATH" ]; then
        echo "❌ 错误：目录不存在: $PROJECT_PATH"
        return 1
    fi

    # 切换到项目目录
    cd "$PROJECT_PATH" || { echo "❌ 无法进入目录 $PROJECT_PATH"; return 1; }

    # 1. 执行 Git Pull
    branch=$(git branch)
    echo "?? 正在$branch分支pull"
    echo "1. 执行 git pull..."
    git pull || { echo "❌ git pull 失败，请检查网络或冲突。"; return 1; }
    git switch test 
    # 2. 执行 NPM Install
    echo "2. 执行 npm ci..."
    npm ci --unsafe-perm || { echo "❌ npm ci 失败，请检查依赖或网络。"; return 1; }
    if [ $? -ne 0 ]; then
        echo "❌ npm ci 过程中出现错误，请检查日志。"
        return 1
    fi
    # 3. 启动开发服务器
    echo "3. 执行 npm run build (测试服务器)..."
    echo "========================================="    
    # 这会启动服务并阻塞终端，直到你按下 Ctrl+C
    npm run build:test

    if [ $? -ne 0 ]; then
        echo "❌ 构建失败，请检查错误日志。"
        return 1
    else
        echo "✅$PROJECT_NAME 构建成功！"
    fi
    echo "-----------------------------------------"
    echo "-----------------------------------------"
    deploy="/opt/deploy-application/frontend"
    case "$PROJECT_NAME" in
        "web-channel")
            cp -r ./dist/* "$deploy/channel.houbaoyan.cn/"
            ;;
        "web-consumer")
            cp  -r ./dist/* "$deploy/consumer.houbaoyan.cn/"
            ;;
        "web-partner")
            cp  -r ./dist/* "$deploy/partner.houbaoyan.cn/"
            ;;
        "web-tms")
            cp  -r ./dist/* "$deploy/tms.houbaoyan.cn/"
            ;;
        "web-recruit-admin")
            cp  -r ./dist/* "$deploy/cms.houbaoyan.cn/"
            ;;
	    "web-yzsys")
	    cp -r ./dist/* "$deploy/tmmnxt.houbaoyan.cn/"
            ;;
        "web-delivery")
	    cp -r ./dist/* "$deploy/address.houbaoyan.cn/"
            ;;
        "web-counselor-system")
        cp -r ./dist/* "$deploy/counselor.houbaoyan.cn/"
            ;;
    	"web-aiAdvisor")
	cp -r ./dist/* "$deploy/advisor.houbaoyan.cn"
        
    esac
    echo "✅ 已将构建文件部署到相应目录！"
    echo "教务服务平台
http://192.168.12.93:8181
渠道服务平台
http://192.168.12.93:8282
学员平台
http://192.168.12.93:8383  
渠道管理平台
http://192.168.12.93:8484
客户关系管理平台
http://192.168.12.93:8585
推免模拟系统
http://192.168.12.93:8686
客户发货平台
http://192.168.12.93:8787
咨询师平台
http://192.168.12.93:8888
ai顾问平台
http://192.168.12.93:8989"

}            

# --- 主程序入口 ---
execute_dev_start

