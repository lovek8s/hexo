---
layout: post
title: 文件系统（一）linux文件系统的选择
author: owelinux
categories: linux
tags: fastdfs
excerpt: linux文件系统的选择
mathjax: true
abbrlink: '55209071'
date: 2018-09-03 10:37:54
---

* content
{:toc}


# linux文件系统的选择

通过综合使用多种标准文件系统Benchmarks对Ext3, Ext4, Reiserfs, XFS, JFS, Reiser4的性能测试对比，
对不同应用选择合适的文件系统给出以下方案，供大家参考。文件系统性能测试数据见附表。


## 1、大量小文件（LOSF, Lost of small files）I/O应用(如小图片)
Reiserfs(首选), Ext4文件系统适合这类负载特征，IO调度算法选择deadline，block size = 4096, ext4关闭日志功能。

reiserfs mount参数：-o defaults, async, noatime, nodiratime, notail, data=writeback

ext4 mount参数：-o defaults, async, noatime, nodiratime, data=writeback, barrier=0关闭ext4日志：tune2fs -O as_journal /dev/sdXX 

## 2、大文件I/O应用(如视频下载、流媒体)
EXT4文件系统适合此类负载特征，IO调度算法选择anticipatory, block size = 4096, 关闭日志功能，启用extent(default)。

mount参数：-o defaults, async, noatime, nodiratime, data=writeback, barrier=0

关闭ext4日志：tune2fs -O as_journal /dev/sdXX 

## 3、SSD文件系统选择
EXT4/Reiserfs可以作为SSD文件系统，但未对SSD做优化，不能充分发挥SSD性能，并影响SSD使用时间。

Btrfs对SSD作了优化，mount通过参数启用。但Btrfs仍处于实验阶段，生产环境谨慎使用。

JFFS2/Nilfs2/YAFFS是常用的flash file system，在嵌入式环境广泛应用，建议使用。性能目前还未作测试评估。

## 简单分析一下选择Reiserfs和ext4文件系统的原因：

### 1、Reiserfs　
大量小文件访问，衡量指标是IOPS，文件系统性能瓶颈在于文件元数据操作、目录操作、数据寻址。

reiserfs对小文件作了优化，并使用B+ tree组织数据，加速了数据寻址，大大降低了
open/create/delete/close等系统调用开销。mount时指定noatime, nodiratime, notail，减少不必要的inode
操作，notail关闭tail package功能，以空间换取更高性能。因此，对于随机的小I/O读写，reiserfs是很好的选择。

### 2、Ext4　
大文件顺序访问，衡量指标是IO吞吐量，文件系统性能瓶颈在于数据块布局(layout)、数据寻址。Ext4对
ext3主要作了两方面的优化:　

*  一是inode预分配。这使得inode具有很好的局部性特征，同一目录文件inode尽量放在一起，加速了目录寻
址与操作性能。因此在小文件应用方面也具有很好的性能表现。　

*  二是extent/delay/multi的数据块分配策略。这些策略使得大文件的数据块保持连续存储在磁盘上，数据寻
址次数大大减少，显著提高I/O吞吐量。
因此，对于顺序大I/O读写，EXT4是很好的选择。另外，XFS性能在大文件方面也相当不错。 


## 感谢

> * 老男孩教育第19期课堂讲解