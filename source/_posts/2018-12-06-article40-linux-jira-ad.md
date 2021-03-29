---
layout: post
title: jira 配置AD域
author: owelinux
categories: linux
tags: linux
excerpt: jira 配置AD域
mathjax: true
abbrlink: bd1aff98
date: 2018-12-06 10:23:54
---

* content
{:toc}

# jira 配置AD域

jira内部认证几种方式：

1、Microsoft 活动目录

是配置Windows的AD账号活动目录的，但是我们不选择这个选项，原因：配置此选项，Jira系统会把Windows目录下的所有账户都同步到Jira用户库，这些用户都被视为活跃用户，如果你的Jira是买的正版，肯定有用户的上限，一旦同步过来的账户超过了上线，超过上限的用户就无法登录Jira，提示用户数达到上限。如果你是破解版的Jira，建议配置这个，方便用户同步和认证。如果是正版用户，推荐配置第三个选项【内部LDAP认证】，原因看下文。

2、LDAP

此配置如上一样的用户同步模式，看自己是否正版用户，自行抉择。

3、内部LDAP认证

重点来了，这个选项的配置的好处是：被加到用户组Jira_users的用户，不会全部同步到Jira用户库中，只有登陆到Jira的用户才会被记录到Jira的用户库，这样就减少了授权用户的资源浪费，因为大多数互联网公司，肯定是使用Jira的用户不到公司总数的1/4，要是选择第1、2种方式，是资源的浪费，不建议。

4、5、配置不做介绍，因为没用过，不过理解的应该是Jira公司自己提供的认证系统。


##  jira 配置AD域

### 1、建立AD账户和相应的群组
在Windows AD中创建一个组，如：Jira_users，然后把需要登录Jira的AD账号，添加为此组成员。


### 配置jira的认证目录

以管理员登陆--管理--用户管理--用户目录--添加目录
![](https://owelinux.github.io/images/2018-12-06-article40-linux-jira-ad/jira-ad.png)

其余配置均使用默认，然后点击测试，提示连接测试成功，说明配置正确，没有问题。再点击【测试并保存】，如果正常返回到【用户管理】页面，说明第二步配置正确完成。

###  给用户组分配权限

第一步：
管理员身份登陆---【系统】---【安全】---【全局权限】---【添加权限】---【权限】---【选择“JIRA 管理员”】--【用户组选择】--【添加】。

第二步：
管理员身份登陆---【应用程序】---【应用程序访问权】---【选择组】----【添加“JIRA Software”权限】，此权限可以授权用户能够能录Jira。

## 参考文档

* [http://www.bigyoung.cn/676.html](http://www.bigyoung.cn/676.html)

* [https://serviceaide.atlassian.net/wiki/spaces/CloudSMGoldfishCN/pages/3703745/ADSync](https://serviceaide.atlassian.net/wiki/spaces/CloudSMGoldfishCN/pages/3703745/ADSync)