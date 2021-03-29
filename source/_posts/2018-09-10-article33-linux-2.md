---
layout: post
title: linux 系统时区更改
author: owelinux
categories: linux
tags: linux
excerpt: linux 系统时区更改
mathjax: true
abbrlink: 9221d952
date: 2018-09-10 18:29:54
---

* content
{:toc}

# linux 系统时区更改

方法一：

``` 
tzselect
```

方法二: 仅限于RedHat Linux 和 CentOS系统 
```
timeconfig
```

方法三: 适用于Debian
``` 
dpkg-reconfigure tzdata
```

方法四: 复制相应的时区文件，替换CentOS系统时区文件；或者创建链接文件 
```
cp /usr/share/zoneinfo/EST5EDT /etc/localtime 
或者 
ln -s /usr/share/zoneinfo/EST5EDT /etc/localtime
时间同步 
yum instlal ntp -y
加入crontab 
* * * * * /usr/sbin/ntpdate us.pool.ntp.org | logger -t NTP
```

时间服务器地址：
[https://www.ntppool.org/zone](https://www.ntppool.org/zone)