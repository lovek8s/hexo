---
layout: post
title: 虚拟机磁盘扩容(适合所有lvm类型)
author: owelinux
categories: linux
tags: linux
excerpt: 虚拟机磁盘扩容(适合所有lvm类型)
mathjax: true
abbrlink: 61bc90fc
date: 2018-08-31 11:37:54
---

* content
{:toc}

# 虚拟机磁盘扩容(适合所有lvm类型)
这里以convirt为例！

## 1.物理机新建磁盘
```
[root@sz-145-centos24 ~]# cd /data/convirt/vm_disks
[root@sz-145-centos24 vm_disks]# qemu-img create -f raw sz-145-centos177-2.xm 10G
```

## 2.convirt平台修改虚拟机配置
关机后修改为如下配置

![](https://owelinux.github.io/images/2018-08-31-article23-linux-convirt-create/convirt-lvm.png)

修改完成后重启虚拟机，生效配置。

## 3.登陆虚拟机配置lvm

### 1、查看是否有新增的磁盘(这里为/dev/sdb)
```
[root@sz-145-centos177 ~]# fdisk  -l | grep Disk
Disk /dev/sda: 125.8 GB, 125829120512 bytes
Disk identifier: 0x0000ec73
Disk /dev/sdb: 10.7 GB, 10737418240 bytes
Disk identifier: 0x00000000
Disk /dev/mapper/vg_templet-lv_root: 116.9 GB, 116912029696 bytes
Disk identifier: 0x00000000
Disk /dev/mapper/vg_templet-lv_swap: 8388 MB, 8388608000 bytes
Disk identifier: 0x00000000
```
### 2、创建pv
```
[root@sz-145-centos177 ~]# pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created
```
### 3、查看vg name 
```
[root@sz-145-centos177 ~]# vgdisplay 
  --- Volume group ---
  VG Name               vg_templet
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  3
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               116.70 GiB
  PE Size               4.00 MiB
  Total PE              29874
  Alloc PE / Size       29874 / 116.70 GiB
  Free  PE / Size       0 / 0   
  VG UUID               kC3k3E-kTBv-isC7-7c7F-VhJu-YBHH-JinGkb
```
### 4、扩容vg
```   
[root@sz-145-centos177 ~]# vgextend vg_templet /dev/sdb 
  Volume group "vg_templet" successfully extended
``` 

### 5、扩容lv
```
[root@sz-145-centos177 ~]# num=`vgdisplay |grep "Free" |awk '{print $5}'`
[root@sz-145-centos177 ~]# lvresize -l +$num /dev/vg_templet/lv_root 
  Size of logical volume vg_templet/lv_root changed from 108.88 GiB (27874 extents) to 118.88 GiB (30433 extents).
  Logical volume lv_root successfully resized.
```
### 6、LV分区重设大小
```
[root@sz-145-centos177 ~]# resize2fs /dev/mapper/vg_templet-lv_root 
resize2fs 1.41.12 (17-May-2010)
Filesystem at /dev/mapper/vg_templet-lv_root is mounted on /; on-line resizing required
old desc_blocks = 7, new_desc_blocks = 8
Performing an on-line resize of /dev/mapper/vg_templet-lv_root to 31163392 (4k) blocks.
The filesystem on /dev/mapper/vg_templet-lv_root is now 31163392 blocks long.
```

### 7.检查扩容后磁盘情况
```
[root@sz-145-centos177 ~]# df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/vg_templet-lv_root
                      117G  2.9G  109G   3% /
tmpfs                 1.9G     0  1.9G   0% /dev/shm
/dev/sda1             477M   39M  413M   9% /boot
```
