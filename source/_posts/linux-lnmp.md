---
title: Lnmp一键部署脚本
top: false
cover: false
toc: true
mathjax: true
date: '2018-07-16 22:34:54 +0800'
tags:
  - lnmp
categories:
  - linux
abbrlink: 24beeabf
password:
summary:
---
## Lnmp一键部署脚本

```
#!/bin/bash
##DATE:2016-7-25
##USER:owelinux
###install wallet

#######install mysql##################################################
yum -y install cmake ncurses-devel  bison libaio  make gcc gcc-c++
mkdir  -p /application/tools
cd /application/tools
wget http://pkgs.fedoraproject.org/repo/pkgs/community-mysql/mysql-boost-5.7.14.tar.gz/f90464874ee635ff63c436d1b64fe311/mysql-boost-5.7.14.tar.gz
tar xvf mysql-boost-5.7.14.tar.gz
cd mysql-5.7.14/
cmake . -DCMAKE_INSTALL_PREFIX=/application/mysql/ \
-DMYSQL_DATADIR=/data/mysqlData/mysql21406/  \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1  \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci  \
-DDOWNLOAD_BOOST=1 \
-DDOWNLOAD_BOOST=1  \
-DWITH_BOOST=./boost/ #boost路径修改一下 指向你源码路径
make  -j4 && make install

groupadd mysql
useradd -M -g mysql -s /sbin/nologin mysql
chown -R mysql:mysql /application/mysql

mkdir -p /data/mysqlData/mysql21406
mkdir /data/mysqlData/mysql21406/binlog
mkdir /data/mysqlData/mysql21406/relaylog
chmod 750 /data/mysqlData/mysql21406/binlog
chmod 750 /data/mysqlData/mysql21406/relaylog
chown -R mysql:mysql /data/mysqlData/*

 # 初始化mysql
/application/mysql/bin/mysqld --initialize --user=mysql --basedir=/application/mysql/ --datadir=/data/mysqlData/mysql21406/data
/application/mysql/bin/mysql_ssl_rsa_setup -d /data/mysqlData/mysql21406/data/

#上传mys.cnf配置文件
cd /data/mysqlData/mysql21406
chown -R mysql:mysql /data/mysqlData/mysql21406

# 修改配置文件
vim /data/mysqlData/mysql21406/my.cnf

# 启动mysql
/application/mysql/bin/mysqld_safe --defaults-file=/data/mysqlData/mysql21406/my.cnf --user=mysql &
/application/mysql/bin/mysql -uroot -S /data/mysqlData/mysql21406/mysql.sock -p

# 设置root密码
SET PASSWORD =PASSWORD('root');
SET PASSWORD FOR username=PASSWORD('new password');
create database zabbix character set utf8 collate utf8_bin;
grant all privileges on zabbix.* to 'zabbix'@'%'  identified by 'zabbix';
flush privileges;


# 设置开机自启动
echo "export PATH=\$PATH:/application/mysql/bin">>/etc/profile
source /etc/profile
echo '/application/mysql/bin/mysqld_safe --defaults-file=/data/mysqlData/mysql21406/my.cnf --user=mysql &' >>/etc/rc.local

#安装nginx######################################################
#useradd -M -s /sbin/nologin nginx
#mkdir -p /var/log/nginx
#cd /application/tools
#wget http://nginx.org/download/nginx-1.10.1.tar.gz
#tar zxvf nginx-1.10.1.tar.gz
#cd nginx-1.10.1
#yum -y install epel-release
#yum -y install openssl openssl-devel  gcc C pcre pcre-devel bzip2-devel libcurl-devel libpng-devel libmcrypt-devel libxml2-devel readline-devel freetype freetype-devel
#./configure --user=nginx --group=nginx --prefix=/application/nginx --with-http_stub_status_module --with-http_ssl_module
#make && make install
yum -y install openssl openssl-devel  gcc C pcre pcre-devel bzip2-devel libcurl-devel libpng-devel libmcrypt-devel libxml2-devel readline-devel gd-devel perl-devel perl-ExtUtils-Embed

#安装openresty
yum -y install epel-release
yum -y install openssl openssl-devel  gcc C pcre pcre-devel bzip2-devel libcurl-devel libpng-devel libmcrypt-devel libxml2-devel libxslt-devel readline-devel gd-devel perl-devel perl-ExtUtils-Embed
mkdir -p /application/tools
cd /application/tools
wget https://openresty.org/download/openresty-1.13.6.1.tar.gz
tar zxvf openresty-1.13.6.1.tar.gz
cd openresty-1.13.6.1
./configure \
--prefix=/application/openresty \
--with-http_iconv_module \
--with-luajit \
--user=nginx \
--group=nginx \
--with-select_module \
--with-poll_module \
--with-threads \
--with-ipv6 \
--with-http_v2_module \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_xslt_module \
--with-http_xslt_module=dynamic \
--with-http_image_filter_module \
--with-http_image_filter_module=dynamic \
--with-http_sub_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_auth_request_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_degradation_module \
--with-http_slice_module \
--with-http_stub_status_module \
--with-http_perl_module \
--with-http_perl_module=dynamic \
--with-stream \
--with-stream=dynamic \
--with-stream_ssl_module \
--with-pcre \
--with-pcre-jit
gmake -j4 && gmake install

useradd -s /sbin/nologin -M nginx
ln -sv /application/openresty/nginx  /application/nginx
ln -s /application/openresty/nginx/sbin/nginx  /usr/sbin/nginx \
/application/nginx/sbin/nginx

# 设置开机自启动
echo "export PATH=\$PATH:/application/openresty/nginx/sbin" >>/etc/profile
source /etc/profile
chmod +x /etc/rc.local
echo "/application/openresty/nginx/sbin/nginx" >>/etc/rc.local

mkdir -p /data/tmp/nginx/client_temp
mkdir -p /data/tmp/nginx/proxy_temp
chmod 711 /data/tmp/nginx

#安装php###############################################
yum -y install epel-release
#cd /application/tools
#wget http://www.atomicorp.com/installers/atomic
#sh ./atomic
yum -y install  gcc gcc-c++   C  autoconf  make mcrypt  mhash zlib zlib-devel pcre pcre-devel  libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel openssl openssl-devel openldap openldap-devel nss_ldap openldap-clients openldap-servers libxslt libxslt-devel libmcrypt libmcrypt-devel libpng12 libpng12-devel libcurl  libcurl-devel readline-devel libXpm-devel gmp gmp-devel  mysql-devel unixODBC unixODBC-devel pspell-devel net-snmp net-snmp-devel
cd /application/tools
wget http://cn2.php.net/distributions/php-7.1.2.tar.gz
tar -zxvf php-7.1.2.tar.gz
cd php-7.1.2
./configure \
  --prefix=/application/php7 \
  --with-mysqli=mysqlnd \
  --with-pdo-mysql=mysqlnd \
  --with-iconv \
  --with-iconv-dir=/usr/local/libiconv \
  --with-freetype-dir \
  --without-pear \
  --with-fpm-user=nginx \
  --with-fpm-group=nginx \
  --with-jpeg-dir \
  --with-png-dir \
  --with-zlib \
  --with-zlib-dir \
  --with-bz2  \
  --with-xsl \
  --with-xmlrpc \
  --with-mhash \
  --with-mcrypt \
  --with-gd  \
  --with-openssl    \
  --with-libxml-dir \
  --with-readline \
  --with-gettext \
  --with-pcre-regex \
  --with-curl \
  --disable-rpath \
  --disable-ipv6  \
  --disable-debug \
  --enable-xml \
  --enable-bcmath \
  --enable-shmop \
  --enable-sysvsem \
  --enable-sysvmsg \
  --enable-sysvshm \
  --enable-mbregex \
  --enable-mysqlnd \
  --enable-fpm \
  --enable-mbstring \
  --enable-gd-native-ttf \
  --enable-pcntl \
  --enable-sockets \
  --enable-soap \
  --enable-short-tags \
  --enable-static \
  --enable-ftp \
  --enable-opcache=yes \
  --enable-json \
  --enable-zip\
  --enable-exif \
  --enable-inline-optimization
#ln -s /application/mysql/lib/libmysqlclient.so.20 /usr/lib64
make -j4 && make install

echo "export PATH="/application/php7/bin:\$PATH"" >>/etc/profile
source /etc/profile
echo "/application/php7/sbin/php-fpm" >>/etc/rc.local

####################################################
php7环境安装模块：
# 安装emqttd
#cd /application/tools
#wget http://emqtt.io/static/brokers/emqttd-centos6.8-v2.1.0-beta.1.zip
#unzip emqttd-centos6.8-v2.1.0-beta.1.zip
#cd emqttd
#./bin/emqttd start
#./bin/emqttd_ctl status

# 安装memcache、redis、yaf模块
#cd /application/tools
#wget http://pecl.php.net/get/memcache-2.2.5.tgz
#tar xf memcache-2.2.5.tgz
#cd memcache-2.2.5
#/application/php/bin/phpize
#./configure --with-php-config=/application/php/bin/php-config
#make && make install

# 安装yaf模块
cd /application/tools
wget https://pecl.php.net/get/yaf-3.0.5.tgz
tar -zxvf yaf-3.0.5.tgz
cd yaf-3.0.5
/application/php7/bin/phpize
./configure --with-php-config=/application/php7/bin/php-config
make && make install

# 安装redis模块
cd /application/tools
wget https://github.com/phpredis/phpredis/archive/develop.zip
unzip develop.zip
cd phpredis-develop
/application/php7/bin/phpize
./configure --with-php-config=/application/php7/bin/php-config
make && make install

# 安装seaslog模块
cd /application/tools
wget https://pecl.php.net/get/SeasLog-1.6.9.tgz
tar -zxvf SeasLog-1.6.9.tgz
cd SeasLog-1.6.9
/application/php7/bin/phpize
./configure --with-php-config=/application/php7/bin/php-config
make && make install

# 安装rabbitmq模块
yum -y install cmake
cd /application/tools
wget https://github.com/alanxz/rabbitmq-c/releases/download/v0.8.0/rabbitmq-c-0.8.0.tar.gz
tar -zxvf rabbitmq-c-0.8.0.tar.gz
cd rabbitmq-c-0.8.0
#mkdir build && cd build
#cmake -DCMAKE_INSTALL_PREFIX=/usr/local/librabbitmq ..
#cmake --build .
./configure --prefix=/usr/local/rabbitmq-c
make -j4 && make install
cd /application/tools
wget https://pecl.php.net/get/amqp-1.9.1.tgz
tar -zxvf amqp-1.9.1.tgz
cd amqp-1.9.1
/application/php7/bin/phpize
./configure --with-php-config=/application/php7/bin/php-config --with-amqp --with-librabbitmq-dir=/usr/local/rabbitmq-c/
make -j4 && make install

##php7环境配置
cd /application/tools/php-7.1.2
\cp php.ini-production  /application/php7/lib/php.ini
cd /application/php7/etc
\cp php-fpm.conf.default php-fpm.conf
cd /application/php7/etc/php-fpm.d/
\cp www.conf.default  www.conf
/application/php7/sbin/php-fpm

# 最后在php.ini定义加载模块就可以
cat >>/application/php7/lib/php.ini<<EOF
date.timezone = "Asia/Shanghai"
extension=redis.so
extension=seaslog.so
extension=yaf.so
extension = amqp.so
yaf.environ=cloud

seaslog.default_basepath = /data/appLog/wallet            ;默认log根目录
seaslog.default_logger = default                        ;默认logger目录
seaslog.disting_type = 1                                ;是否以type分文件 1是 0否(默认)
seaslog.disting_by_hour = 1                             ;是否每小时划分一个文件 1是 0否(默认)
seaslog.use_buffer = 0                                  ;是否启用buffer 1是 0否(默认)
seaslog.buffer_size = 100                               ;buffer中缓冲数量 默认0(不使用buffer_size)
seaslog.level = 0                                       ;记录日志级别 默认0(所有日志)
seaslog.trace_error = 1                                 ;自动记录错误 默认1(开启)
seaslog.trace_exception = 0                             ;自动记录异常信息 默认0(关闭)
seaslog.default_datetime_format = "Y:m:d H:i:s"         ;日期格式配置 默认"Y:m:d H:i:s"
seaslog.appender = 1                                    ;日志存储介质 1File 2TCP 3UDP (默认为1)
seaslog.remote_host = 127.0.0.1                         ;接收ip 默认127.0.0.1 (当使用TCP或UDP时必填)
seaslog.remote_port = 514                               ;接收端口 默认514 (当使用TCP或UDP时必填)
EOF
#重启php-fpm
pkill php-fpm
/application/php7/sbin/php-fpm

# 服务开机自启动
cat >>/etc/rc.local<<EOF
/application/php/sbin/php-fpm
/application/nginx/sbin/nginx
/application/mysql/bin/mysqld_safe --defaults-file=/data/mysqlData/mysql21406/my.cnf --user=mysql &
EOF

# 内核调优
cat >>/etc/sysctl.conf<<EOF
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog =  32768
net.core.somaxconn = 32768

net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

net.ipv4.tcp_tw_recycle = 1
#net.ipv4.tcp_tw_len = 1
net.ipv4.tcp_tw_reuse = 1

net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800

#net.ipv4.tcp_fin_timeout = 30
#net.ipv4.tcp_keepalive_time = 120
net.ipv4.ip_local_port_range = 1024  65535
EOF
/sbin/sysctl -p
```