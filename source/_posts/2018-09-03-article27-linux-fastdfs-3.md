---
layout: post
title: '文件系统（三）fastdfs和其他文件系统区别 '
author: owelinux
categories: linux
tags: fastdfs
excerpt: 本来想写点fastdfs内容，发现有总结非常好的博文，这里拿出来分享给大家
mathjax: true
abbrlink: 414cbe1f
date: 2018-09-03 11:43:54
---

* content
{:toc}

# fastdfs和其他文件系统区别

## 一、概述

普通存储方案：Rsync、DAS(IDE/SATA/SAS/SCSI等块)、NAS(NFS、CIFS、SAMBA等文件系统)、SAN(FibreChannel, iSCSI, FoE存储网络块)，Openfiler、FreeNas(ZFS快照复制)由于生产环境中往往由于对存储数据量很大，而SAN存储价格又比较昂贵，因此大多会选择分布式
存储来解决一下问题：

* 海量数据存储问题
* 数据高可用问题(冗余备份)问题
* 较高的读写性能和负载均衡问题
* 支持多平台多语言问题
* 高并发问题

主要对别指标 csdn这表格太难用了，我还是word整理后搬到这儿来的。

![](https://owelinux.github.io/images/2018-09-03-article27-linux-fastdfs-3/fastdfs3.png)

## 二、常用的分布式文件系统

常见的分布式文件系统有FastDFS，GFS、HDFS、Ceph 、GridFS 、mogileFS、TFS等。各自适用于不同的领域。它们都不是系统级的分布式文件系统，而是应用级的分布式文件存储服务。

### FastDFS介绍
请参照FastDFS文件系统(一) fastdfs是什么? 

### GFS（Google File System）
Google公司为了满足本公司需求而开发的基于Linux的专有分布式文件系统。。尽管Google公布了该系统的一些技术细节，但Google并没有将该系统的软件部分作为开源软件发布。
下面分布式文件系统都是类 GFS的产品。

### HDFS（Hadoop Distributed File System）
Hadoop 实现了一个分布式文件系统，主要用于大数据计算存储，简称HDFS。 Hadoop是Apache Lucene创始人Doug Cutting开发的使用广泛的文本搜索库。它起源于Apache Nutch，后者是一个开源的网络搜索引擎，本身也是Luene项目的一部分。Aapche Hadoop架构是MapReduce算法的一种开源应用，是Google开创其帝国的重要基石。

### Ceph

github：[https://github.com/ceph/ceph](https://github.com/ceph/ceph)

是加州大学圣克鲁兹分校的Sage weil攻读博士时开发的分布式文件系统。Ceph能够在维护 POSIX 兼容性的同时加入了复制和容错功能。Sage weil并使用Ceph完成了他的论文。说 ceph 性能最高，C++编写的代码，支持Fuse，并且没有单点故障依赖， 于是下载安装， 由于 ceph 使用 btrfs 文件系统， 而btrfs 文件系统需要 Linux 2.6.34 以上的内核才支持。

### GridFS文件系统
MongoDB是一种知名的NoSql数据库，GridFS是MongoDB的一个内置功能，它提供一组文件操作的API以利用MongoDB存储文件，GridFS的基本原理是将文件保存在两个Collection中，一个保存文件索引，一个保存文件内容，文件内容按一定大小分成若干块，每一块存在一个Document中，这种方法不仅提供了文件存储，还提供了对文件相关的一些附加属性（比如MD5值，文件名等等）的存储。文件在GridFS中会按4MB为单位进行分块存储。

### MogileFS
由memcahed的开发公司danga一款perl开发的产品，目前国内使用mogielFS的有图片托管网站yupoo等。
MogileFS是一套高效的文件自动备份组件，由Six Apart开发，广泛应用在包括LiveJournal等web2.0站点上。
MogileFS由3个部分组成：

* 第1个部分是server端，包括mogilefsd和mogstored两个程序。前者即是 mogilefsd的tracker，它将一些全局信息保存在数据库里，例如站点domain,class,host等。后者即是存储节点(store node)，它其实是个HTTP Daemon，默认侦听在7500端口，接受客户端的文件备份请求。在安装完后，要运行mogadm工具将所有的store node注册到mogilefsd的数据库里，mogilefsd会对这些节点进行管理和监控。

* 第2个部分是utils（工具集），主要是MogileFS的一些管理工具，例如mogadm等。
　　
* 第3个部分是客户端API，目前只有Perl API(MogileFS.pm)、PHP，用这个模块可以编写客户端程序，实现文件的备份管理功能。


### TFS
TFS（Taobao !FileSystem）是一个高可扩展、高可用、高性能、面向互联网服务的分布式文件系统，主要针对海量的非结构化数据，它构筑在普通的Linux机器 集群上，可为外部提供高可靠和高并发的存储访问。TFS为淘宝提供海量小文件存储，通常文件大小不超过1M，满足了淘宝对小文件存储的需求，被广泛地应用 在淘宝各项应用中。它采用了HA架构和平滑扩容，保证了整个文件系统的可用性和扩展性。同时扁平化的数据组织结构，可将文件名映射到文件的物理地址，简化 了文件的访问流程，一定程度上为TFS提供了良好的读写性能。

官网 ： [http://code.taobao.org/p/tfs/wiki/index/](http://code.taobao.org/p/tfs/wiki/index/)

## 参考

> * [https://blog.csdn.net/wk313753744/article/details/49943835](https://blog.csdn.net/wk313753744/article/details/49943835)