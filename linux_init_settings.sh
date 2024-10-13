# 来自 - https://mp.weixin.qq.com/s/VAaYVeaz5DuQ_cp0RMc7ug
#环境变量
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

#当前时间
current_time=$(date +%Y%m%d)

#阿里的DNS
dns_server=223.5.5.5 

if [[ ! -z `uname -r|grep 'el6'` ]]
  then
  kernel_version=el6
  yum_repo=http://mirrors.aliyun.com/repo/Centos-6.repo
elif [[ ! -z `uname -r|grep 'el7'` ]]
  then
  kernel_version=el7
  yum_repo=http://mirrors.aliyun.com/repo/Centos-7.repo
else
  echo -e "\e[31mUnidentified Kernel version: $(uname -r). Only support for kernel el6/el7\e[0m"
  exit
fi

function add_yum_repo(){
  local item="Add Aliyun Yum Mirrors"
  yum clean all
  cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.${current_time} && \
  curl -o /etc/yum.repos.d/CentOS-Base.repo ${yum_repo} > /dev/null 2>&1
  show_result $? "${item}"
  yum makecache
}

function show_result(){
  if [ "$1" -eq 0 ]
    then
      echo -e "\e[32m$2 is Success .   [ OK ] \e[0m"
    else
      echo -e "\e[31m$2 is Fail .   [ FAIL ] \e[0m"
  fi
}

function add_newconfig_tofile(){
  local SearchResult=`grep "$1" "$2"`
  if [ -z "${SearchResult}" ]
    then
    echo "$1" >> $2
  fi
}

function add_config_tofile(){
  local keywords=`echo $1| awk -F "[= ]+" '{print $1}'`
  local SearchResult=`grep "^${keywords}" "$2"`
  if [ -z "${SearchResult}" ] #空为真，非空为假
    then
    echo $1 >> $2
  else
    sed -i "s/^${keywords}.*/$1/" $2
  fi
}

function config_localtime(){
  local item="Config SH As Location"
  rm -f /etc/localtime
  ln -s  /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  show_result $? "${item}"
}

function config_dns_addr(){
  local item="Config DNS Address"
  cp /etc/resolv.conf /etc/resolv.conf.${current_time} && \
  echo "nameserver ${dns_server}" > /etc/resolv.conf
  show_result $? "${item}"
}

function maximum_file_dspt(){
  local item="Maximum File Descriptor"
  cp /etc/security/limits.conf /etc/security/limits.conf.${current_time} && \
  echo "*           soft    nofile          100000
*           hard    nofile          100000
*           soft    nproc           65535
*           hard    nproc           65535
*           soft    core            unlimited
*           hard    core            unlimited" > /etc/security/limits.conf
  show_result $? "${item}"
}


function shutdown_nonuse_srv(){
  local item="Shutdown Unused Services"
  if [[ "${kernel_version}" == el6 ]]
      then
    for i in `chkconfig --list | awk '{print $1}'`
      do
      chkconfig --level 2345 $i off > /dev/null 2>&1
      done
    for ii in crond network rsyslog sshd sysstat haldaemon
      do
      chkconfig --level 2345 $ii on > /dev/null 2>&1
      done
    show_result $? "${item}"
  elif [[ "${kernel_version}" == el7 ]]
    then
    systemctl disable postfix > /dev/null 2>&1
    show_result $? "${item}"
  else
    echo -e "\e[31mUnidentified Kernel version: $(uname -r). Only support for kernel el6/el7\e[0m"
  fi
}

function optimize_kel_args(){
  local item="Optimize Kernel Arguments"
  cp /etc/sysctl.conf /etc/sysctl.conf.${current_time} > /dev/null 2>&1
  arch_ratio=$([[ ! -z $(uname -a | grep x86_64) ]] && expr 64 / 32 || expr 32 / 32)
  memory_size=$(free -b| awk 'NR==2{print $2}')
  nf_conntrack_size=$(expr ${memory_size} / 16384 / ${arch_ratio})
  #开启反向路径过滤
  add_config_tofile "net.ipv4.conf.default.rp_filter = 1" /etc/sysctl.conf
  add_config_tofile "net.ipv4.conf.all.rp_filter = 1" /etc/sysctl.conf
  #处理无源路由包
  add_config_tofile "net.ipv4.conf.all.accept_source_route = 0" /etc/sysctl.conf
  add_config_tofile "net.ipv4.conf.default.accept_source_route = 0" /etc/sysctl.conf
  #core文件名中添加pid作为扩展名
  add_config_tofile "kernel.core_uses_pid = 1" /etc/sysctl.conf
  #开启syn洪水攻击保护
  add_config_tofile "net.ipv4.tcp_syncookies = 1" /etc/sysctl.conf
  #修改消息队列长度
  add_config_tofile "kernel.msgmnb = 65536" /etc/sysctl.conf
  add_config_tofile "kernel.msgmax = 65536" /etc/sysctl.conf
  #修改最大内存共享段大小bytes
  add_config_tofile "kernel.shmmax = 68719476736" /etc/sysctl.conf
  add_config_tofile "kernel.shmall = 4294967296" /etc/sysctl.conf
  #timewait数量默认18000
  add_config_tofile "net.ipv4.tcp_max_tw_buckets = 600" /etc/sysctl.conf
  add_config_tofile "net.ipv4.tcp_sack = 1" /etc/sysctl.conf
  add_config_tofile "net.ipv4.tcp_window_scaling = 1" /etc/sysctl.conf
  add_config_tofile "net.ipv4.tcp_rmem = 4096 87380 16777216" /etc/sysctl.conf
  add_config_tofile "net.ipv4.tcp_wmem = 4096 65536 16777216" /etc/sysctl.conf
  add_config_tofile "net.core.rmem_default = 8388608" /etc/sysctl.conf
  add_config_tofile "net.core.wmem_max = 16777216" /etc/sysctl.conf
  #未收到客户端确认信息连接请求的最大值
  add_config_tofile "net.ipv4.tcp_max_syn_backlog = 262144" /etc/sysctl.conf
  #放弃建立连接之前发送的synack包
  add_config_tofile "net.ipv4.tcp_syn_retries = 2" /etc/sysctl.conf
  #开启重用，允许time—wait socket 重新用语新的tcp连接
  add_config_tofile "net.ipv4.tcp_tw_reuse = 1" /etc/sysctl.conf
  add_config_tofile "net.ipv4.tcp_fin_timeout = 1" /etc/sysctl.conf
  #防止简单的ddos攻击
  add_config_tofile "net.ipv4.tcp_max_orphans = 3276800" /etc/sysctl.conf
  #启用timewait快速收回
  add_config_tofile "net.ipv4.tcp_tw_recycle = 0" /etc/sysctl.conf
  #keeptime启用时tcp发送keepalive消息的频度，默认2h
  add_config_tofile "net.ipv4.tcp_keepalive_time = 600" /etc/sysctl.conf
  #允许系统打开的端口范围
  add_config_tofile "net.ipv4.ip_local_port_range = 1024 65535" /etc/sysctl.conf
    #资源回收
    add_config_tofile "net.ipv4.tcp_tw_recycle = 0" /etc/sysctl.conf
    #路由转发
    add_config_tofile "net.ipv4.ip_forward = 1" /etc/sysctl.conf 
  #修改防火墙连接跟踪表大小，默认65535
  add_config_tofile "net.netfilter.nf_conntrack_max = ${nf_conntrack_size}" /etc/sysctl.conf
  add_config_tofile "net.nf_conntrack_max = ${nf_conntrack_size}" /etc/sysctl.conf
  #解禁ping
  add_config_tofile "net.ipv4.icmp_echo_ignore_all = 0" /etc/sysctl.conf
      modprobe bridge
  sysctl -p > /dev/null 2>&1
  show_result $? "${item}"
}

function install_pkgs(){
  local item="Install Common Pkgs"
  yum -y groupinstall "Development libraries" > /dev/null 2>&1
  yum -y groupinstall "Development tools" > /dev/null 2>&1
  yum -y install sysstat  tree  lrzsz  telnet wget net-tools tcpdump lsof vim ntp > /dev/null 2>&1
  show_result $? "${item}"
}

function shutdown_selinux(){
  local item="Shutdown Selinux "
  setenforce 0 > /dev/null 2>&1
  cp /etc/selinux/config /etc/selinux/config.${current_time} && \
  sed -i 's:SELINUX=enforcing:SELINUX=disabled:g' /etc/selinux/config
  show_result $? "${item}"
}

function main(){
  echo -e '\033[34;1m开始初始化操作系统中......\033[0m'
  # 设置时区为上海
  timedatectl set-timezone Asia/Shanghai
  # 开启同步网络时间
  timedatectl set-ntp true
  add_yum_repo
  install_pkgs
  config_localtime
  config_dns_addr
  maximum_file_dspt
  shutdown_nonuse_srv
  shutdown_selinux
  optimize_kel_args
  echo -e '\033[34;1m服务器系统初始化已完成！\033[0m'
}

main
