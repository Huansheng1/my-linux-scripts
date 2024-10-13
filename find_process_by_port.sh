#!/usr/bin/sudo /bin/bash
#
#           Huansheng1 my-linux-scripts
#   GitHub: https://github.com/Huansheng1/my-linux-scripts
#
#   使用方式
#   root用户执行：wget -qO- https://ghp.ci/https://raw.githubusercontent.com/Huansheng1/my-linux-scripts/main/find_process_by_port.sh | bash
#
#   This only work on  Linux systems. Please
#   open an issue if you notice any bugs.
#

clear

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检测操作系统发行版
detect_distro() {
    local distro
    distro=$(awk -F= '/^ID=/ {print $2}' /etc/os-release | tr -d '"')
    case "$distro" in
        "centos") 
            DISTRO="CentOS"
            ;;
        "ubuntu") 
            DISTRO="Ubuntu"
            ;;
        "debian") 
            DISTRO="Debian"
            ;;
        "fedora") 
            DISTRO="Fedora"
            ;;
        *)
            DISTRO="unknown"
            ;;
    esac
}

detect_distro

# 根据操作系统发行版安装 lsof
install_lsof() {
    case "$DISTRO" in
        "CentOS")
            sudo yum install -y lsof
            ;;
        "Ubuntu"|"Debian")
            sudo apt-get update && sudo apt-get install -y lsof
            ;;
        "Fedora")
            sudo dnf install -y lsof
            ;;
        *)
            echo -e "${RED}不支持的操作系统发行版：$DISTRO${NC}"
            exit 1
            ;;
    esac
}

# 检查 lsof 命令是否存在
if ! command -v lsof &> /dev/null; then
    echo -e "${YELLOW}系统中未找到 lsof 命令，是否现在安装？(y/n)${NC}"
    read -r install_choice
    if [[ $install_choice =~ ^[Yy]$ ]]; then
        install_lsof
    else
        echo -e "${RED}用户取消了安装 lsof 命令。${NC}"
        exit 1
    fi
fi

# 检查是否输入了端口号
if [ $# -eq 0 ]; then
    read -p "请输入端口号：" PORT
else
    PORT=$1
fi

# 查找占用指定端口的进程
PROCESSES=$(lsof -i :$PORT | awk 'NR>1 {print $2}')

if [ -z "$PROCESSES" ]; then
    echo -e "${RED}未找到占用端口 $PORT 的进程。${NC}"
else
    echo -e "${GREEN}找到以下进程占用端口 $PORT：${NC}"
    echo "$PROCESSES"
    read -p "请输入要杀死的进程ID（多个ID用空格分隔）：" PIDS

    # 杀死指定的进程
    IFS=' ' read -r -a PID_ARRAY <<< "$PIDS"
    for PID in "${PID_ARRAY[@]}"; do
        kill -9 $PID
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}进程ID $PID 已被成功杀死。${NC}"
        else
            echo -e "${RED}进程ID $PID 杀死失败。${NC}"
        fi
    done
fi
