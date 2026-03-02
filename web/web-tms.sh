#!/bin/bash
BASE_DIR="/opt/builds/frontend"  #构建路径
PROJECTS="web-tms"  #服务名称
PROJECT_PATH="$BASE_DIR/$PROJECTS"
echo ""
echo "========================================="
echo "🚀 正在处理项目: $PROJECTS (位于 $PROJECT_PATH)"
echo "========================================="
echo ""

# 切换到项目目录
cd "$PROJECT_PATH" || { echo "❌ 无法进入目录 $PROJECT_PATH"; return 1; }
# 1. 执行 Git Pull
    git switch test
    branch=$(git branch)
    echo "?? 正在$branch 分支pull"
    echo "1. 执行 git pull..."
    git pull || { echo "❌ git pull 失败，请检查网络或冲突。"; return 1; }
    
    # 验证当前使用的 Node/npm 版本
    echo "?? 验证版本: Node $(node --version), npm $(npm --version)"
    # ----------------------------------------------------
    # 2. 执行 NPM ci
    echo "2. 执行 npm ci..."
    npm ci --unsafe-perm || { echo "❌ npm ci 失败，请检查依赖或网络。"; return 1; }
    if [ $? -ne 0 ]; then
        echo "❌ npm ci 过程中出现错误，请检查日志。"
        return 1
    fi
    # 3. 启动开发服务器
    echo "3. 执行 npm run build (测试服务器)..."
    echo "========================================="    
    # 这会启动服务并阻塞终端，直到你按下 Ctrl+Cx    
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
    #删除当前路径下以往版本
    rm -rf "$deploy/tms.houbaoyan.cn/"* || { echo "删除失败" ; exit 1; }
    echo "已删除当前路径$deploy/tms.houbaoyan.cn/所有文件"
    echo "-----------------------------------------"
    echo "-----------------------------------------"
    #复制到服务路径下
    cp -r ./dist/* "$deploy/tms.houbaoyan.cn/" || { echo "复制失败" ; exit 1; }
    echo "dist包复制到$deploy/tms.houbaoyan.cn/"
    echo "-----------------------------------------"
    echo "-----------------------------------------"
    

    echo "教务服务平台 http://192.168.12.93:8181"