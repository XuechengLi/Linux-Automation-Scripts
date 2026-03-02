前端多个项目同时构建部署
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
    
    # 2. 执行 NPM Install
    echo "2. 执行 npm ci..."
    #npm ci --unsafe-perm || { echo "❌ npm ci 失败，请检查依赖或网络。"; return 1; }
    npm ci  --verbose

    # 3. 启动开发服务器
    echo "3. 执行 npm run dev:test (开发服务器)..."
    echo "========================================="
    DEV_PID=$!
    echo $DEV_PID
    
    # 这会启动服务并阻塞终端，直到你按下 Ctrl+C
    npm run dev:test 
}

# --- 主程序入口 ---
execute_dev_start

