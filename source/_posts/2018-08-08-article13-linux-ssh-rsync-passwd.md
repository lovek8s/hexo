---
layout: post
title: Linux适用于ssh协议免密登录
author: owelinux
categories: linux
tags: linux ssh
excerpt: Linux适用于ssh协议免密登录.
mathjax: true
abbrlink: 3acc515a
date: 2018-08-08 15:41:54
---

* content
{:toc}

# Linux适用于ssh协议免密登录

免密应用场景：自动化运维、定时同步、跳板机等

## ssh密钥方式

### 生成和导入key
A服务器执行：
```
$ssh-keygen 
$ll /root/.ssh/
总用量 12
-rw-------. 1 root root 1675 8月   8 16:39 id_rsa
-rw-r--r--. 1 root root  393 8月   8 16:39 id_rsa.pub
-rw-r--r--. 1 root root  184 7月  17 16:06 known_hosts
```
> * id_rsa:私钥
> * id_rsa.pub：公钥

### 拷贝密钥并授权：
```
方法一：
$cat /root/.ssh/id_rsa.pub | ssh root@远程服务器B 'cat - >> ~/.ssh/authorized_keys'
方法二：
$ssh-copy-id  -i /root/.ssh/id_rsa root@远程服务器B
```
### ssh_config配置
> * PubkeyAuthentication yes  //将该项改为yes
> * UsePAM yes ;如果想禁用密码登录改为：UserPAM no

### 测试
```
$ssh root@远程服务器B
```

### 问题排查

注：对于普通用户authorized_keys的权限必须限定为600（go-rwx），否则普通用户无法实现无密钥访问，而ROOT用户按照默认即可实现无密钥访问
chmod go-rwx ~/.ssh/authorized_keys

不能免密登录多半是权限问题：
> * .ssh的权限700， 
> * authorized_keys的权限600
> * 排错日志：/var/log/secure

## rsync/scp+ssh+密码登录
```
$yum -y install rsync sshpass
```
sshpass常用命令选项：
> * -f 密码文件
> * -p 密码
> * -e 密码不显示屏幕   

```
ssh：
$sshpass -f password_filename ssh remote_user@remote_host 'df -h'

scp:
$scp -r /local/dir --rsh="sshpass -p 'my_pass_here' ssh -l remote_user" remote_host:/remote/dir

rsync:
$rsync --rsh="sshpass -p 'my_pass_here' ssh -l remote_user" remote_host:/remote/dir /local/dir
or
$sshpass -p remote_password rsync -avz --delete -e ssh remote_user@remote_host:/remote/dir /local/dir
```
上面的命令中:
> * remote_use/remote_password是远程的密码
> * -avz是打包传送、显示明细、压缩
> * -e ssh是关键，即over ssh
> * 我们要从远程同步到本地
> * /remote/dir是远程服务器路径
> * /local/dir是本地服务器路径
