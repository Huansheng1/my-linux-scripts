#!/usr/bin/sudo /bin/bash
#
#           Huansheng1 my-linux-scripts
#   GitHub: https://github.com/Huansheng1/my-linux-scripts
#
#   使用方式
#   root用户执行：wget -qO- https://ghp.ci/https://raw.githubusercontent.com/Huansheng1/my-linux-scripts/main/QLToolsV2_fast_install_or_uninstall.sh | bash
#
#   This only work on  Linux systems. Please
#   open an issue if you notice any bugs.
#

clear
# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

announce_url="https://ghp.ci/https://raw.githubusercontent.com/Huansheng1/my-qinglong-js/main/announce.txt"
echo -e "${YELLOW}正在拉取公告信息，请稍等...${NC}"
announce_content=$(curl -s "$announce_url")
if [ $? -eq 0 ]; then
    echo -e "${GREEN}${announce_content}${NC}"

    # 提示用户输入版本号，默认为1.0.3
    echo -e "${YELLOW}版本列表请前往 [https://github.com/nuanxinqing123/QLToolsV2/releases] 查看!!!${NC}"
    echo "请输入 [QLToolsV2] 版本号（直接回车使用默认版本 1.0.3）:"
    read VERSION
    VERSION=${VERSION:-1.0.3}  # 如果未输入，则使用默认值 1.0.3

    # 定义下载链接
    AMD_URL="https://gh-proxy.com/https://github.com/nuanxinqing123/QLToolsV2/releases/download/$VERSION/QLToolsV2-linux-amd64"
    ARM_URL="https://gh-proxy.com/https://github.com/nuanxinqing123/QLToolsV2/releases/download/$VERSION/QLToolsV2-linux-arm64"

    # 输出或使用这些链接
    echo "你选择了青龙工具2.0的版本号是: $VERSION >>> 正在处理~"

    # 检测服务器架构
    ARCH=$(uname -m)

    # 根据架构选择下载链接
    if [ "$ARCH" = "x86_64" ]; then
        DOWNLOAD_URL=$AMD_URL
    elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        DOWNLOAD_URL=$ARM_URL
    else
        echo -e "${RED}不支持的系统架构 Unsupported architecture: $ARCH${NC}"
        exit 1
    fi

    # 定义目标目录和配置目录
    TARGET_DIR="/etc/hs_helper/ql_tools_v2"
    CONFIG_DIR="/etc/hs_helper/ql_tools_v2/config"
    SERVICE_NAME="ql_tools_v2.service"

    # 检测目标目录是否存在
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}青龙工具2.0已安装 QLToolsV2 is already installed.${NC}"
        echo "1. 重新安装 Uninstall and reinstall"
        echo "2. 单纯卸载 Uninstall only"
        read -p "请选择一个选项 Choose an option: " option

        if [ "$option" = "1" ]; then
            echo -e "${YELLOW}卸载中 Uninstalling QLToolsV2...${NC}"
            # 停止服务
            if systemctl is-active --quiet $SERVICE_NAME; then
                systemctl stop $SERVICE_NAME
            fi
            # 以防万一，通过pkill再次强行停止服务
            pkill -f ql_tools_v2
            # 移除文件
            rm -rf "$TARGET_DIR"
            # 清除systemd服务
            if [ -f "/etc/systemd/system/$SERVICE_NAME" ]; then
                rm "/etc/systemd/system/$SERVICE_NAME"
                systemctl daemon-reload
            fi
        elif [ "$option" = "2" ]; then
            echo -e "${YELLOW}卸载中 Uninstalling QLToolsV2...${NC}"
            # 停止服务
            if systemctl is-active --quiet $SERVICE_NAME; then
                systemctl stop $SERVICE_NAME
            fi
            # 移除目录
            rm -rf "$TARGET_DIR"
            # 清除systemd服务
            if [ -f "/etc/systemd/system/$SERVICE_NAME" ]; then
                rm "/etc/systemd/system/$SERVICE_NAME"
                systemctl daemon-reload
            fi
            echo -e "${GREEN}青龙工具2.0 已卸载完毕 QLToolsV2 has been uninstalled.${NC}"
            exit 0
        else
            echo -e "${RED}选项输入错误 Invalid option.${NC}"
            exit 1
        fi
    fi

    # 创建目标目录和配置目录
    mkdir -p "$TARGET_DIR"
    mkdir -p "$CONFIG_DIR"

    # 切换到目标目录
    cd "$TARGET_DIR"

    # 下载文件
    wget -O ql_tools_v2 $DOWNLOAD_URL

    # 给可执行文件赋予权限
    chmod +x ql_tools_v2

    # 提示用户输入port和signing-key
    read -p "请输入面板端口号 (回车默认为1500) Enter the port number: " port
    port=${port:-1500}

    read -p "请输入令牌秘钥 (回车默认为Huansheng1_tools) Enter the signing key: " signing_key
    signing_key=${signing_key:-Huansheng1_tools}

    # 下载配置文件
    wget -O "$CONFIG_DIR/config.yaml" https://gh-proxy.com/https://raw.githubusercontent.com/nuanxinqing123/QLToolsV2/main/config/example.config.yaml

    # 使用sed替换配置文件中的端口号和签名密钥
    sed -i "s/port: \(.*\)/port: $port/" "$CONFIG_DIR/config.yaml"
    sed -i "s/signing-key: '\(.*\)'/signing-key: '$signing_key'/" "$CONFIG_DIR/config.yaml"

    # 检测是否支持systemctl
    if command -v systemctl >/dev/null; then
        # 创建systemd服务文件
        cat > "/etc/systemd/system/$SERVICE_NAME" << EOF
[Unit]
Description=QLToolsV2 Service
After=network.target

[Service]
ExecStart=$TARGET_DIR/ql_tools_v2
Restart=on-failure
User=root
WorkingDirectory=$TARGET_DIR

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable $SERVICE_NAME
        systemctl start $SERVICE_NAME
        echo -e "${GREEN}青龙工具2.0安装并设置为跟随系统启动完毕 QLToolsV2 installed and enabled to start on boot.${NC}"
    else
        # 使用nohup启动服务
        nohup ./ql_tools_v2 &
        echo -e "${YELLOW}系统不支持使用systemctl设置自启服务，仅启动软件成功 Systemd not found, QLToolsV2 started in background but will not start on boot.${NC}"
    fi

    # 提示安装并启动完毕
    # 获取内网IP地址
    # 自动检测默认网关对应的网络接口
    default_gateway=$(ip route | grep default | awk '{print $5}')
    internal_ip=$(ip addr show $default_gateway | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

    # 检查是否成功获取内网IP
    if [ -z "$internal_ip" ]; then
        echo -e "${GREEN}无法获取内网IP地址，请检查网络配置。${NC}"
        exit 1
    fi

    # 获取公网IP地址
    public_ip_json=$(curl -s 'https://whois.pconline.com.cn/ipJson.jsp?ip=&json=true')
    public_ip=$(echo "$public_ip_json" | jq -r '.ip')

    # 检查是否成功获取公网IP
    if [ -z "$public_ip" ]; then
        echo -e "${GREEN}无法获取公网IP地址，请检查网络连接或API是否可用。${NC}"
        exit 1
    fi

    # 输出结果
    echo -e "${GREEN}安装工作全部做完了，快访问下面的地址来体验面板吧~\n"
    echo -e "内网IP地址: http://$internal_ip:$port\n"
    echo -e "公网IP地址: http://$public_ip:$port\n"
    echo -e "Installation and startup are complete. Please visit it ${NC}"
fi
