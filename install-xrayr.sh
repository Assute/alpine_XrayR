#!/bin/sh
# 更新软件源
apk update
# 安装依赖项
apk add wget unzip openrc

# 创建OpenRC运行目录（添加部分）
mkdir -p /run/openrc
mkdir -p /run/openrc/start
touch /run/openrc/start/XrayR
touch /run/openrc/softlevel

# 获取XrayR最新版本号
echo "正在获取XrayR最新版本号..."
VERSION=$(wget -qO- https://api.github.com/repos/XrayR-project/XrayR/releases/latest | grep "tag_name" | cut -d'"' -f4 || echo "v0.9.4")
echo "最新版本: $VERSION"

# 下载XrayR最新版本
ZIP_URL="https://github.com/XrayR-project/XrayR/releases/download/${VERSION}/XrayR-linux-64.zip"
echo "正在下载XrayR $VERSION..."
wget "$ZIP_URL" -O XrayR-linux-64.zip || { echo "下载失败，使用备用版本"; wget https://github.com/XrayR-project/XrayR/releases/download/v0.9.4/XrayR-linux-64.zip -O XrayR-linux-64.zip; }

# 解压缩
unzip XrayR-linux-64.zip -d /etc/XrayR

# 添加执行权限
chmod +x /etc/XrayR/XrayR

# 创建软链接
ln -s /etc/XrayR/XrayR /usr/bin/XrayR

# 创建XrayR服务文件（修正参数格式）
cat > /etc/init.d/XrayR <<EOF
#!/sbin/openrc-run

depend() {
    need net
}

start() {
    ebegin "Starting XrayR"
    start-stop-daemon --start --exec /usr/bin/XrayR -- --config /etc/XrayR/config.yml
    eend $?
}

stop() {
    ebegin "Stopping XrayR"
    start-stop-daemon --stop --exec /usr/bin/XrayR
    eend $?
}

restart() {
    ebegin "Restarting XrayR"
    start-stop-daemon --stop --exec /usr/bin/XrayR
    sleep 1
    start-stop-daemon --start --exec /usr/bin/XrayR -- --config /etc/XrayR/config.yml
    eend $?
}
EOF

# 添加执行权限
chmod +x /etc/init.d/XrayR

# 添加新启动项（适用于OpenRC系统）
mkdir -p /etc/runlevels/default
ln -s /etc/init.d/XrayR /etc/runlevels/default/XrayR

# 添加到开机启动项中
rc-update add XrayR default

echo "安装完成！XrayR $VERSION 已安装并配置为开机启动。"
echo "请编辑配置文件: /etc/XrayR/config.yml"
echo "然后启动服务: /etc/init.d/XrayR start"