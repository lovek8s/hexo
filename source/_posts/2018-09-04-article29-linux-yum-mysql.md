---
layout: post
title: centos yum安装mysql5.7
author: owelinux
categories: linux
tags: mysql
excerpt: centos yum安装mysql5.7
mathjax: true
abbrlink: 30f05cdb
date: 2018-09-04 16:02:54
---

* content
{:toc}

#centos yum安装mysql5.7

在测试开发环境，初始化一个数据库，通常选择yum来安装，本文将常见的mysqlyum源及安装方式梳理

## 系统环境
centos6或者centos7

## 查看系统是否已经安装mysql

```
rpm -qa | grep mysql
yum list installed | grep mysql
```
## 卸载当前数据库
centos6.x或者centos7.x ：
```
yum -y remove mysql*
```

## mysql数据源下载
centos6.x
```
yum install -y http://repo.mysql.com//mysql57-community-release-el6-8.noarch.rpm
```
centos7.x
```
yum install -y http://repo.mysql.com/mysql57-community-release-el7-8.noarch.rpm
```

## mysql安装
```
yum install -y mysql-community-server
```

## mysqlroot密码修改
```
# 启动数据库
service mysqld start
# 查看密码
cat  /var/log/mysqld.log |  grep "password" | grep "generated" 
# 登陆数据库
mysql-uroot -p
# 修改密码
SET PASSWORD = PASSWORD('your new password');
ALTER USER 'root'@'localhost' PASSWORD EXPIRE NEVER;
flush privileges;
```

## mysql常用操作

设置字符集：
```
# 在 [mysqld] 前添加如下代码：
[client]
default-character-set=utf8

# 在 [mysqld] 后添加如下代码：
character_set_server=utf8

# 重启mysql后再登录，看看字符集，6个utf8就算OK
show variables like '%character%';
```

忘记密码时，重置密码：
```
service mysqld stop
mysqld_safe --user=root --skip-grant-tables --skip-networking &
mysql -u root
进入MySQL后

use mysql;
update user set password=password("new_password") where user="root"; 
flush privileges;
```

数据库授权：
```
grant all privileges on *.* to uaername@"%" identified by "new password";
```

数据库设置密码复杂度：

* validate_password_dictionary_file: 插件用于验证密码强度的字典文件路径。

* validate_password_length: 密码最小长度，参数默认为8，它有最小值的限制，最小值为：validate_password_number_count + validate_password_special_char_count + (2 * validate_password_mixed_case_count)

* validate_password_mixed_case_count: 密码至少要包含的小写字母个数和大写字母个数。

* validate_password_number_count: 密码至少要包含的数字个数。

* validate_password_policy: 密码强度检查等级，0/LOW、1/MEDIUM、2/STRONG

```
修改mysql参数配置

mysql> set global validate_password_policy=0;
Query OK, 0 rows affected (0.05 sec)

mysql> set global validate_password_mixed_case_count=0;
Query OK, 0 rows affected (0.00 sec)
 
mysql> set global validate_password_number_count=3;
Query OK, 0 rows affected (0.00 sec)
 
mysql> set global validate_password_special_char_count=0;
Query OK, 0 rows affected (0.00 sec)
 
mysql> set global validate_password_length=3;
Query OK, 0 rows affected (0.00 sec)
 
mysql> SHOW VARIABLES LIKE 'validate_password%';
+--------------------------------------+-------+
| Variable_name                        | Value |
+--------------------------------------+-------+
| validate_password_dictionary_file    |       |
| validate_password_length             | 3     |
| validate_password_mixed_case_count   | 0     |
| validate_password_number_count       | 3     |
| validate_password_policy             | LOW   |
| validate_password_special_char_count | 0     |
+--------------------------------------+-------+
6 rows in set (0.00 sec)

# 修改简单密码：
mysql> SET PASSWORD =PASSWORD('root');
mysql> SET PASSWORD FOR username=PASSWORD('new password');
```