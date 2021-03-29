---
layout: post
title: linux 根据进程/端口排错
author: owelinux
categories: linux
tags: linux
excerpt: linux 根据进程/端口排错
mathjax: true
abbrlink: bea17661
date: 2018-09-10 18:29:54
---

* content
{:toc}

# linux 根据进程/端口排错

## linux根据进程号PID查找启动程序的全路径

获取进程号
``` 
ps -ef| grep 'pidname'
```

根据进程查找路径
```
ls -ail /proc/pid/
```

## 根据端口号查找到进程占用
a.
``` 
lsof -i:port
```
b.
```
netstat -lntp | grep 'port'
```

## 根据服务名查找端口占用
```
pgrep -f nginx
```