---
layout: post
title: convirt2.5安装及报错解决
author: owelinux
categories: linux
tags: linux  convirt
excerpt: convirt2.5安装及报错解决
mathjax: true
abbrlink: 1de0ee9f
date: 2018-08-30 17:37:54
---

* content
{:toc}

# convirt2.5安装及报错解决

## 1.配置convirt源
```
cd/etc/yum.repos.d;
wget   --no-cache http://www.convirture.com/repos/definitions/rhel/6.x/convirt.repo
```

## 2.安装socat
```
yum install socat
```

## 3.配置代理服务器，没有的话就跳过这一步
```
export http_proxy="http://company-proxy-server:80"
```
## 4.Convirt网站下载所需要的包
```
$ wget --no-cache http://www.convirture.com/downloads/convirt/2.5/convirt-install-2.5.tar.gz;
$ wget --no-cache http://www.convirture.com/downloads/convirt/2.5/convirt-2.5.tar.gz;
$ wget --no-cache http://www.convirture.com/downloads/convirture-tools/2.5/convirture-tools-2.5.tar.gz
$ tar -xzf convirt-install-2.5.tar.gz
```
## 5.下载virtualenv和python
```
wget --no-check-certificate https://pypi.python.org/packages/source/v/virtualenv/virtualenv-1.11.6.tar.gz
wget --no-check-certificate https://www.python.org/ftp/python/2.6.6/Python-2.6.6.tgz
tar zxvf virtualenv-1.11.6.tar.gz=
cd virtualenv-1.11.6
python setup.py install
cd /root
tar zxvf Python-2.6.6.tgz
cd Python-2.6.6
./configure
make && make install
```
## 6.安装依赖
```
cd  ~/convirt-install/install/cms/scripts/;
./install_dependencies
```

## 7.配置数据库
Centos6下自动安装的是mysql，centos7下自动安装的是mariadb数据库，需要替换掉，看”Centos7下安装mysql”文档
 执行到后面会启动mysqld服务，需要用户密码，因为预先安装的mysql，没有设置root密码，直接按enter键。设置root密码，重复两次（例密码：root）。

然后系统询问是否删除匿名用户（Y/N），“Y“！

不允许root远程连接(Y/N)，”Y”.

删除预置的test数据库(Y/N),”Y”.

马上重新载入特权表(Y/N),”Y”.

### 设置 innodb 缓存和内存池
```
vim /etc/my.cnf
[mysqld]下添加下面两行

innodb_buffer_pool_size=1G
innodb_additional_mem_pool_size=20M
```
### 重启mysql服务
```
/etc/init.d/mysqld   restart
```

## 8.安装ConVirt
```
cd  ~/convirt-install/install/cms/scripts
vim install_config

# 将CONVIRT-BASE=~改为CONVIRT-BASE=/usr/local

source  ~/convirt-install/install/cms/scripts/install_config
 
tar  -xzf   convirt-2.5.tar.gz  -C $CONVIRT_BASE
```
## 9.设置 TurboGears (python的轻量级框架)
```
/usr/local/convirt/tg2env/bin/pip install funcsigs

cd /usr/local/convirt/tg2env/lib
ln -s python2.6/ python2.4

cd python2.6/site-packages/
ln -s Beaker-1.3-py2.6.egg Beaker-1.3-py2.4.egg
ln -s Beaker-1.10.0-py2.6.egg Beaker-1.10.0-py2.4.egg

~/convirt-install/install/cms/scripts/setup_tg2
```

## 10.设置 ConVirt
```
vim /usr/local/convirt/src/convirt/web/convirt/development.ini 

“/sqlalchemy.url”命令查找其位置
#sqlalchemy.url=postgres://username:password@hostname:port/databasename?charset=utf8

sqlalchemy.url=mysql://root:root@localhost:3306/convirt?charset=utf8
```

注：后台收集的cpu、内存等信息都会保存到数据库中，默认为365天，数据量非常大，造成后期mysql查询很慢，磁盘IO很高，如果机器性能不好，应该修改下面的参数，来减少数据保存的时间：
```
purge_hr_data = 60

purge_day_data = 30

purge_week_data = 30

purge_month_data =30

purge_raw_data = 30

task_results_purge_interval=30

TaskPaneLimit=7

task_panel_row_limit=200

notifications_row_limit=200
```
 

刚才设置的mysql密码为root。

然后执行$~/convirt-install/install/cms/scripts/setup_convirt

会要求输入passPhrase。

Enterpassphrase(empty for no passphrase):记住密语以后会用到（例：testOS）

Entersame  passphrase again: 记住密语以后会用到（例：testOS）

在cms启动时也会用到，通过密语来连接cms和managed server

PS：

如果在这里出现 convirt-ctl   setup error 同意思的字样，可能得删除数据库中的convirt数据库，然后重新执行

```
~/convirt-install/install/cms/scripts/setup_convirt
```

有时候mysql数据库是用root用户启动的，那么cms也必须用root用户启动

##11.使CMS设置生效

### a)启动cms服务
```
/usr/local/convirt/convirt-ctl  start
```

服务名称为：paster  代理服务:ssh-agent
```
ps  -e | grep paster
```

### b)如果开启着防火墙，配置访问策略（root权限）
```
iptables -I INPUT -p tcp --dport 8081 -j  ACCEPT
```

### c)验证是否运行成功
不成功就重启下cms服务和防火墙，返回a).b)

如果多次启动仍然不成功，切换到root用户再次重试

在另一台机器上浏览器中输入：http://192.168.108.83:8081


###  d)错误
```
a.
No local packages or download links found for funcsigs
error: Could not find suitable distribution for Requirement.parse('funcsigs')
ERROR: installing TG2 (2.0.3).
ERROR: Failed creating Turbogears2 environment.
解决：
/usr/local/convirt/tg2env/bin/pip install funcsigs
```
b.
```
ls: cannot access /usr/local/convirt/tg2env/lib/python2.4/site-packages/Beaker-*py2.4.egg/beaker/ext/google.py: No such file or directory
TurboGears environmnet setup successfully.
解决：

cd /usr/local/convirt/tg2env/lib
ln -s python2.6/ python2.4

cd python2.6/site-packages/
ln -s Beaker-1.3-py2.6.egg Beaker-1.3-py2.4.egg
ln -s Beaker-1.10.0-py2.6.egg Beaker-1.10.0-py2.4.egg
```
## 部署Managed Servers

### Centos中安装KVM。
```
yum -y groupinstall 'Virtualization' 'Virtualization Client' 'VirtualizationPlatform' 'Virtualization Tools'
```

### 修改网络设置
```
[root@centos244 ~]# cat /etc/sysconfig/network-scripts/ifcfg-eth0 
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=none
BRIDGE=br0

[root@centos244 ~]# cat /etc/sysconfig/network-scripts/ifcfg-br0 
DEVICE=br0
ONBOOT=yes
TYPE=Bridge
BOOTPROTO=none
IPADDR=192.168.1.1
PREFIX=24
GATEWAY=192.168.1.1
```
重启网络
```
/etc/init.d/network restart
```
### 检查系统cpu是否支持KVM虚拟化
```
egrep -c ‘(vmx|svm)’ /proc/cpuinfo

0 表示不支持，1 表示支持。
```
### 加载kvm模块
```
modprobe  kvm
modprobe  kvm_amd
modprobe  kvm_intel
```

## 配置convirt-tool
```
[root@cms ~]# cd /usr/local/cms

[root@cms cms]#wget --no-cache http://www.convirture.com/downloads/convirture-tools/2.0.1/convirture-tools-2.0.1.tar.gz

[root@cms cms]# scp convirture-tools-2.0.1.tar.gz root@192.168.5.7:/root/

[root@ cms ~]# ssh root@192.168.5.7

[root@ kvm-test ~]# tar zxvf convirture-tools-2.0.1.tar.gz

[root@ kvm-test ~]# cd convirture-tools/install/managed_server/scripts

[root@ kvm-test scripts]# ./convirt-tool –h    查看帮助

[root@ kvm-test scripts]# ./convirt-tool --detect_only setup   验证platform（平台）而不做更改

[root@kvm-test scripts]# ./convirt-tool install_dependencies 安装所需依赖
```

桥接已经配置过，且没有开启iptables，就执行以下命令：
```
[root@kvm-test scripts]# ./convirt-tool --skip_bridge --skip_firewall setup
```
 
然后，在CMS主机上启动convirt：

其中的输出信息中，/root/.ssh/cms_id_rsa这个东西很重要，涉及之后虚拟机的vnc连接问题。

至此，安装成功！

## 添加Managed Server

登录http://192.168.9.21：:8081，用户名admin，密码admin


## 配置VNC管理

在CMS主机上配置ssh代理，注意回显是否成功

一般，convirt_ctl启动的时候，会创建~/.ssh/cms_id_rsa文件

如果没有，就手动创建：
```
[root@cms ~]# ssh-keygen -t rsa -f ~/.ssh/cms_id_rsa

[root@cms ~]# chmod 0600 ~/.ssh/cms_id_rsa*

[root@cms ~]# eval `ssh-agent -s`

Agent pid 16323

[root@cms ~]# ssh-add .ssh/cms_id_rsa

Identity added: .ssh/cms_id_rsa (.ssh/cms_id_rsa)

[root@cms .ssh]# ssh root@kvm-test

Last login: Tue Apr 24 17:20:35 2012 from cms
```
 
再登陆kvm-test主机，就无需输入密码了，如果还需要输入密码，可以执行：
```
[root@cms ~]# scp ~/.ssh/cms_id_rsa.pub root@kvm-test:/root/.ssh/vnc_proxy_id_rsa.pub

[root@cms ~]# ssh root@kvm-test

[root@kvm-test ~]# cat vnc_proxy_id_rsa.pub >> authorized_keys
```

启动VCN代理转发：
```
[root@cms ~]# socat -d -d -d -d TCP-LISTEN:6900 EXEC:’/usr/bin/ssh root@kvm-test socat - TCP\:127.0.0.1\:5902’ > /tmp/6900_5902_qKhAFc.log 2>&1 &
```

使用命令创建convirt虚拟机：
```
[root@kvm-test ~]# /usr/libexec/qemu-kvm -hda "/data/kvm/c2_appliance.disk.xm" -net "nic,vlan=0,macaddr=00:16:3e:20:d4:44" -net "user,vlan=0"  -boot "c" -m "512" -vnc ":25" -name "convirt_appliance" -smp "2" -redir tcp:2222::22 -redir tcp:8888::8081 -daemonize
```

## 登录web管理

管理虚拟机时通过VNC applet来实现，所以必需浏览器中有java的支持：

## 参考
> * [https://blog.csdn.net/kisssun0608/article/details/44885635](https://blog.csdn.net/kisssun0608/article/details/44885635)
> * [https://support.accelerite.com/hc/en-us/articles/206179510-ConVirt-Enterprise-3-4-5-Setup-for-Fedora-RHEL-CentOS](https://support.accelerite.com/hc/en-us/articles/206179510-ConVirt-Enterprise-3-4-5-Setup-for-Fedora-RHEL-CentOS)
> * [https://blog.csdn.net/kobe283734280/article/details/7827482](https://blog.csdn.net/kobe283734280/article/details/7827482)