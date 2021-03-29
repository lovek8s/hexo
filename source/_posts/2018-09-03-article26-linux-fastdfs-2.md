---
layout: post
title: '文件系统（二）fastdfs是什么? '
author: owelinux
categories: linux
tags: fastdfs
excerpt: 本来想写点fastdfs内容，发现有总结非常好的博文，这里拿出来分享给大家
mathjax: true
abbrlink: f14b4aeb
date: 2018-09-03 10:43:54
---

* content
{:toc}

# fastdfs是什么? 

## 一、FastDFS概述

FastDFS是阿里巴巴开源的一套轻量级,天生就是分布式设计的文件系统，FastDFS的源代码由C语言开发，目前可运行在Linux,FreeBSD，Unix等类操作系统上，FastDFS解决了大数据量文件存储和读写分离,备份容错,负载均衡,动态扩容等问题，这也就是原作者所描述的高性能和高扩展性的文件系统。适合存储4KB~500MB之间的小文件，如图片网站、短视频网站、文档、app下载站等。

## 二、FastDFS作者简介

FastDFS的作者是余庆(happyfish100)，github地址[https://github.com/happyfish100](https://github.com/happyfish100)

## 三、FastDFS主要特性

1.为互联网量身定制，海量数据文件存储。

2.高可用(同组备份机制)。

3.FastDFS不是通用的文件系统，只能通过api来访问，目前提供c,java,php客户端。phtyon由第三方开发者提供。

4;FastDFS可以看作是基于key/value pair存储系统，也许称为分布式文件存储服务更合适。

5;支持高并发(这个好像没体现出支持什么高并发,这个是nginx的功劳吧)

## 四、主要用户

* 京东(http://www.jd.com/),主要商品图片存储,可以看出来这是fastdfs典型路径
  http://img12.360buyimg.com/n9/g15/M08/0B/19/rBEhWVMdbUMIAAAAAAEo7QHfEvoAAJwzAC7VvkAASkF751.jpg

* UC(http://www.uc.cn/),主要提供网盘服务

* 支付宝(https://www.alipay.com/)

* Lockbur高清壁纸分享网站(http://www.lockbur.com/),主要提供小图片存储服务。

## 参考

> * [https://blog.csdn.net/wk313753744/article/details/49943155](https://blog.csdn.net/wk313753744/article/details/49943155)