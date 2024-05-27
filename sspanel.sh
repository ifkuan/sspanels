#/bin/bash

# Date : 2024-05-27 22:07:23

# Author : GZ

# Mail : v2board@qq.com

# Function : 脚本介绍

# Version : V1.0


# 检查用户是否为root用户
if [ $(id -u) != "0" ]; then
    echo "Error: 您必须是root才能运行此脚本，请使用root安装sspanel"
    exit 1
fi

process()
{
install_date="sspanel_install_$(date +%Y-%m-%d_%H:%M:%S).log"
printf "
\033[36m#######################################################################
#                     欢迎使用sspanel一键部署脚本                     #
#                脚本适配环境Ubuntu 22.04+/Debian 11+、内存1G+        #
#                请使用干净主机部署！                                 #
#                更多信息请访问 https://gz1903.github.io              #
#######################################################################\033[0m
"

# 设置数据库密码
while :; do echo
    read -p "请输入Mysql数据库root密码: " Database_Password 
    [ -n "$Database_Password" ] && break
done

#获取主机内网ip
ip="$(ifconfig|grep "inet "|awk '{print $2;exit;}')"
#获取主机外网ip
ips="$(curl ip.sb)"

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                    正在安装常用组件 请稍等~                         #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# 更新必备基础软件
apt update && apt upgrade -y
apt install -y curl vim wget unzip apt-transport-https lsb-release ca-certificates git gnupg2

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                  正在配置Firewall策略 请稍等~                       #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
sudo ufw allow 80
#放行TCP80端口

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                 正在安装MariaDB数据库 请稍等~                       #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# MariaDB 是 MySQL 关系数据库管理系统的一个复刻，由社区开发，有商业支持，旨在继续保持在 GNU GPL 下开源。
# MariaDB 与 MySQL 完全兼容
# 选取官方源的镜像进行安装 MariaDB 10.11 稳定版本
curl -o /etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc 'https://mariadb.org/mariadb_release_signing_key.asc'
sh -c "echo 'deb https://atl.mirrors.knownhost.com/mariadb/repo/10.11/debian bullseye main' >>/etc/apt/sources.list"
apt update
apt install mariadb-server -y



echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#         正在安装Nginx环境  时间较长请稍等~                          #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# 添加 官方源
sudo add-apt-repository 'deb https://nginx.org/packages/debian/ bullseye nginx'
sudo add-apt-repository 'deb-src https://nginx.org/packages/debian/ bullseye nginx'
wget  https://nginx.org/keys/nginx_signing.key
# 安装 nginx最新版
apt-key add nginx_signing.key
apt update
apt install nginx
# 检测Nginx版本
nginx -V


echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#         正在安装配置PHP环境及扩展  时间较长请稍等~                  #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# 设置Debian官方PHP源
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
curl -fsSL  https://packages.sury.org/php/apt.gpg| sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
apt update 
# 安装PHP 8.2，如果需要其他版本，自行替换
apt install php8.2 -y
apt install php8.2-{bcmath,fpm,xml,mysql,zip,intl,ldap,gd,cli,bz2,curl,mbstring,pgsql,opcache,soap,cgi,xmlrpc,mcrypt,fileinfo,redis,swoole,readline,inotify} -y

#apt 不能安装的，用pecl install 命令安装
#先安装pecl
curl -O https://pear.php.net/go-pear.phar
sudo php -d detect_unicode=0 go-pear.phar

#用pear安装event扩展
apt install -y php8.2-cli php8.2-dev libevent-dev
pecl install event -y

# 开机自启
sudo systemctl enable php8.2-fpm

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                   正在配置Mysql数据库 请稍等~                       #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
#修改数据库密码
mysqladmin -u root password "$Database_Password"
echo -e "\033[36m数据库密码设置完成！\033[0m"
#创建数据库
mysql -uroot -p$Database_Password -e "CREATE DATABASE sspanel CHARACTER set utf8 collate utf8_bin;"
echo $?="正在创建sspanel数据库"

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                    正在配置Nginx 请稍等~                            #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# 删除默认配置
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/sspanel.conf
touch /etc/nginx/sites-available/sspanel.conf
cat > /etc/nginx/sites-available/sspanel.conf <<"eof"
server {  
    listen 80;
    listen [::]:80;
    root /var/www/sspanel/public; # 改成你自己的路径，需要以 /public 结尾
    index index.php index.html;
    server_name guagua.publicvm.com www.guagua.publicvm.com; # 改成你自己的域名

    location / {
        try_files $uri /index.php$is_args$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
}
eof
# 配置软连接。
cd /etc/nginx/sites-enabled
ln -s /etc/nginx/sites-available/sspanel.conf sspanel
nginx -s reload

echo -e "\033[36m#######################################################################\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#                   正在编译sspanel软件 请稍等~                       #\033[0m"
echo -e "\033[36m#                                                                     #\033[0m"
echo -e "\033[36m#######################################################################\033[0m"
# 安装sspanel软件包
# 清空目录文件全新下载
rm -rf /var/www/sspanel
mkdir /var/www/sspanel
cd /var/www/sspanel
git clone https://github.com/ifkuan/GoPassThemeForSSPanel.git ${PWD}


# 下载 composer
git config core.filemode false
wget https://getcomposer.org/installer -O composer.phar
echo -e "\033[32m软件下载安装中，时间较长请稍等~\033[0m"
# 安装 PHP 依赖
php composer.phar
echo -e "\033[32m请输入yes确认安装！~\033[0m"
php composer.phar install  --ignore-platform-reqs 
# 调整目录权限
chmod -R 755 ${PWD}
chown -R www-data:www-data ${PWD}

# 修改配置文件
cd /var/www/sspanel/
cp config/.config.example.php config/.config.php
cp config/appprofile.example.php config/appprofile.php
cp config/.metron_setting.example.php config/.metron_setting.php
cp config/.zeroconfig.example.php config/.zeroconfig.php
# 设置sspanel数据库连接
# 设置此key为随机字符串确保网站安全 !!!
sed -i "s/1145141919810/aksgsj@h$RANDOM/" /var/www/sspanel/config/.config.php
# 站点名称
sed -i "s/SSPanel-UIM/小满/" /var/www/sspanel/config/.config.php
# 站点地址
sed -i "s/https:\/\/sspanel.host/http:\/\/$ips/" /var/www/sspanel/config/.config.php
# 用于校验魔改后端请求
sed -i "s/NimaQu/sadg^#@s$RANDOM/" /var/www/sspanel/config/.config.php
# 设置sspanel数据库连接地址
sed -i "s/host'\]      = ''/host'\]      = '127.0.0.1'/" /var/www/sspanel/config/.config.php
# 设置数据库连接密码
sed -i "s/password'\]  = 'sspanel'/password'\]  = '$Database_Password'/" /var/www/sspanel/config/.config.php
# 导入数据库文件
mysql -uroot -p$Database_Password sspanel < /var/www/sspanel/sql/glzjin_all.sql;
echo -e "\033[36m设置管理员账号：\033[0m"
php xcat User createAdmin
# 重置所有流量
php xcat User resetTraffic
# 下载 IP 地址库
php xcat Tool initQQWry

nginx -s reload
echo $?="服务启动完成"

echo -e "\033[32m--------------------------- 安装已完成 ---------------------------\033[0m"
echo -e "\033[32m 数据库名     :sspanel\033[0m"
echo -e "\033[32m 数据库用户名 :root\033[0m"
echo -e "\033[32m 数据库密码   :"$Database_Password
echo -e "\033[32m 网站目录     :/var/www/sspanel\033[0m"
echo -e "\033[32m 配置目录     :/var/www/sspanel/config/.config.php\033[0m"
echo -e "\033[32m 网页内网访问 :http://"$ip
echo -e "\033[32m 网页外网访问 :http://"$ips
echo -e "\033[32m 安装日志文件 :/var/log/"$install_date
echo -e "\033[32m------------------------------------------------------------------\033[0m"
echo -e "\033[32m 如果安装有问题请反馈安装日志文件。\033[0m"
echo -e "\033[32m 使用有问题请在这里寻求帮助:https://gz1903.github.io\033[0m"
echo -e "\033[32m 电子邮箱:v2board@qq.com\033[0m"
echo -e "\033[32m------------------------------------------------------------------\033[0m"

}

LOGFILE=/var/log/"sspanel_install_$(date +%Y-%m-%d_%H:%M:%S).log"
touch $LOGFILE
tail -f $LOGFILE &
pid=$!
exec 3>&1
exec 4>&2
exec &>$LOGFILE
process
ret=$?
exec 1>&3 3>&-
exec 2>&4 4>&-
