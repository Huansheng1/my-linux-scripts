#!/bin/bash
#
#           Huansheng1 my-linux-scripts
#   GitHub: https://github.com/Huansheng1/my-linux-scripts
#
#   使用方式
#   root用户执行：wget -qO- https://ghp.ci/https://raw.githubusercontent.com/Huansheng1/my-linux-scripts/main/system_monitor.sh | bash
#
#   This only work on  Linux systems. Please
#   open an issue if you notice any bugs.
#
#   来自 - https://mp.weixin.qq.com/s/M2qq93YKvmdsHSLcnm7S_Q
#
#

clear 
function cpu {   
    util=$(vmstat | awk '{if(NR==3)print $13+$14}')   
    iowait=$(vmstat | awk '{if(NR==3)print $16}')   
    echo "CPU -使用率：${util}% ,等待磁盘IO相应使用率：${iowait}:${iowait}%"   
}   
function memory () {   
    total=$(free -m | awk '{if(NR==2)printf "%.1f",$2/1024}')   
    used=$(free -m | awk '{if(NR==2) printf "%.1f",($2-$NF)/1024}')   
    available=$(free -m | awk '{if(NR==2) printf "%.1f",$NF/1024}')   
    echo "内存 - 总大小: ${total}G , 使用: ${used}G , 剩余: ${available}G"   
}   
disk() {   
    fs=$(df -h | awk '/^\/dev/{print $1}')   
    for p in $fs; do   
        mounted=$(df -h | awk '$1=="'$p'"{print $NF}')   
        size=$(df -h | awk '$1=="'$p'"{print $2}')   
        used=$(df -h | awk '$1=="'$p'"{print $3}')   
        used_percent=$(df -h | awk '$1=="'$p'"{print $5}')   
        echo "硬盘 - 挂载点: $mounted , 总大小: $size , 使用: $used , 使用率: $used_percent"   
    done   
}   
function tcp_status () {   
    summary=$(ss -antp | awk '{status[$1]++}END{for(i in status) printf i":"status[i]" "}')   
    echo "TCP连接状态 - $summary"   
}   
cpu   
memory   
disk   
tcp_status
