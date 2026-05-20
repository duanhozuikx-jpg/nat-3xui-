#!/bin/bash
#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "请使用 root 用户运行"
   exit 1
fi

echo "====== 1G1H 小鸡优化开始 ======"

### 1️⃣ 更新系统
if command -v apt &> /dev/null; then
    apt update -y && apt install -y curl wget sudo
elif command -v yum &> /dev/null; then
    yum update -y && yum install -y curl wget sudo
fi

### 2️⃣ 添加 512M 交换分区（防止爆内存）
if [ ! -f /swapfile ]; then
    echo "创建 512M swap..."
    fallocate -l 512M /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=512
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

### 3️⃣ 开启 BBR
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

### 4️⃣ TCP 优化
cat >> /etc/sysctl.conf <<EOF

fs.file-max=1000000
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.netdev_max_backlog=250000
net.core.somaxconn=4096
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30
net.ipv4.ip_local_port_range=1024 65000
EOF

sysctl -p

### 5️⃣ 提高最大连接数
echo "* soft nofile 1000000" >> /etc/security/limits.conf
echo "* hard nofile 1000000" >> /etc/security/limits.conf

### 6️⃣ 关闭 IPv6（NAT 机器建议）
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

### 7️⃣ 安装 3x-ui
echo "开始安装 3x-ui..."
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

### 8️⃣ 关闭不必要服务（节省内存）
systemctl disable --now postfix 2>/dev/null
systemctl disable --now snapd 2>/dev/null
systemctl disable --now apache2 2>/dev/null
systemctl disable --now nginx 2>/dev/null

echo "====== ✅ 优化完成 ======"
echo ""
echo "建议："
echo "1. 面板端口不要用 2053，改成随机端口"
echo "2. 节点协议建议用 VLESS + Reality（最省资源）"
echo "3. 不要开启日志"
echo ""
echo "使用命令：x-ui"
echo ""
echo "重启服务器后优化完全生效"
