---
layout: post
title: GitLab Helm Charts 配置AD域
author: owelinux
categories: linux
tags: linux
excerpt: GitLab Helm Charts 配置AD域
mathjax: true
abbrlink: d1b746a1
date: 2018-12-06 10:23:54
---

* content
{:toc}

# GitLab Helm Charts 配置AD域

gitlab部署方式有很多种，比如：官方yum安装、docker容器部署、k8s部署、k8s helm chart部署


## 1）在Active Directory中创建用户以执行LDAP查询

不要将Gitlab配置为使用管理员帐户执行LDAP查询。而是设置一个没有域权限的新用户：

a. 登录到您的域控制器，然后加载Active Directory用户和计算机

b. 创建一个名为“NoPermissions”的新组

c. 创建一个名为“ldapsearch”的新用户

d. 编辑“ldapsearch”用户组。将默认组设置为“NoPermissions”，并从“Domain User”组中删除该用户。

## 2）编辑您的Gitlab Omnibus配置

### 适用于yum安装、容器部署方式

a. 在Gitlab服务器上，编辑Gitlab配置文件：

vim /etc/gitlab/gitlab.rb

并添加以下设置：
```
gitlab_rails [ 'ldap_enabled' ] = true 
gitlab_rails [ 'ldap_servers' ] = YAML.load << - EOS ＃记得用
main 下面的'EOS'关闭这个块：
标签： 'ActiveDirectory' 
主机： 'YOUR-AD-SERVER.CORP .COM' 
端口： 389 #Change到636如果使用LDAPS 
方法： '纯' ＃更改为“TLS”如果使用LDAPS 
UID ： 'sAMAccountName赋' ＃不要更改此
bind_dn ： CN = ldapsearch的，CN =用户，DC = CORP，DC = COM”
密码：'YOURPASSWORDHERE' 
超时： 10 
active_directory ： true 
allow_username_or_email_login ： false 
block_auto_created_users ： false 
base ： 'CN = Users，DC = CORP，DC = COM' 
＃可选：下一行指定只有用户组“gitlab-users”的成员才能对Gitlab进行身份验证：
#user_filter：'（memberOf：1.2.840.113556.1.4.1941：= CN = GITLAB-USERS，CN = Users，DC = CORP，DC = COM）'
EOS
```
注意： 配置文件是  间隔敏感的！必须有：

* “主要”之前的一个空格
* “main”下面每个属性前的两个空格
* “EOS”之前没有空格

b. gitlab-ctl重新配置

c. 测试与AD服务器的LDAP连接：

gitlab-rake gitlab：ldap：check

### 适用于k8s Helm chart方式部署
在使用helm chart方式部署后，通过修改value.ymal文件添加AD域配置，通过模板渲染到相应配置中
```
global:
  appConfig:
    ldap:
      servers:
        main:
          label: 'LDAP'
          host: x.x.x.x
          port: 389
          uid: 'sAMAccountName'
          method: 'plain'
          bind_dn: 'mysoft\xxxx'
          password: 'xxxx'
          verify_certificates: true
          allow_username_or_email_login: true
          lowercase_usernames: true
          block_auto_reated_users: false
          active_directory: true
          base: 'DC=xxxx,DC=com,DC=cn'
  hosts:
    domain: xxxx.com.cn
  edition: ce
```
 

## 3）故障排除

a. Gitlab服务器连接到AD服务器上的LDAP端口情况

telnet your-ad-server.corp.com 389

b. ldapsearch用户和基本DN是否正确的,可以使用LDAP管理工具验证专有名称。

* Using AdFind (Windows) [AdFind](http://www.joeware.net/freetools/tools/adfind/index.htm)

* Using ldapsearch (Unix)[LDAPUtils](https://wiki.debian.org/LDAP/LDAPUtils)

c. 检查配置文件是否使用正确的YAML格式



## 参考文档

* [https://www.caseylabs.com/setup-gitlab-ce-with-active-directory-authentication/](https://www.caseylabs.com/setup-gitlab-ce-with-active-directory-authentication/)

* [https://docs.gitlab.com/ee/administration/auth/how_to_configure_ldap_gitlab_ce/](https://docs.gitlab.com/ee/administration/auth/how_to_configure_ldap_gitlab_ce/) 