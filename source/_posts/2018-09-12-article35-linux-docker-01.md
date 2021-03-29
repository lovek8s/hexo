---
layout: post
title: Docker 系列01-docker安装
author: owelinux
categories: linux 容器与虚拟化
tags: linux  docker
excerpt: Docker 系列01-docker安装
mathjax: true
abbrlink: ef57bbb7
date: 2018-09-12 18:29:54
---

* content
{:toc}

# Docker 系列01-docker安装

Docker 提供了两个版本：社区版 (CE) 和企业版 (EE)。

Docker 社区版 (CE) 是开发人员和小型团队开始使用 Docker 并尝试使用基于容器的应用的理想之选。Docker CE 有两个更新渠道，即 stable 和 edge：

* Stable 每个季度为您提供可靠更新
* Edge 每个月为您提供新功能

## 支持平台

Docker CE 和 EE 可用于多种平台、云和内部部署。使用下表选择适用于您的最佳安装路径。

### 桌面
* Mac	 
* Windows	
 	 
### 云

* Amazon
* Microsoft
* Digital Ocean
* Packet
* SoftLink
* 使用docker云代理创建自己的主机

### 服务器

* CentOS
* Debian	
* Fedora		 
* Microsoft Windows
* Oracle Linux
* Red Hat
* SUSE

## centos安装docker ce

### 操作系统要求

如需安装 Docker CE，您需要 64 位版本的 CentOS 7。

### 卸载旧版本
Docker 的早期版本称为 docker 或 docker-engine。如果安装了这些版本，请卸载它们及关联的依赖资源。
```
$ sudo yum remove docker \
                  docker-common \
                  docker-selinux \
                  docker-engine
```

将保留 /var/lib/docker/ 的内容，包括镜像、容器、存储卷和网络。Docker CE 软件包现在称为 docker-ce。

### 安装 Docker CE
您可以通过不同方式安装 Docker CE，具体取决于您的需求：

* Docker 的镜像仓库安装(推荐方法。)

* RPM 软件包并手动进行安装

#### 使用yum进行安装
```
 $ sudo yum install -y yum-utils device-mapper-persistent-data lvm2
 $ sudo yum-config-manager \
     --add-repo \
     https://download.docker.com/linux/centos/docker-ce.repo
 $ sudo yum makecache fast
 $ sudo yum install docker-ce
 $ sudo systemctl start docker
```

如需要edge版本，使用以下开启
```
 $ sudo yum-config-manager --enable docker-ce-edge (默认关闭)
 $ sudo yum-config-manager --enable docker-ce-testing (默认关闭)
```

安装特定版本：
```
 $ yum list docker-ce.x86_64  --showduplicates | sort -r

 $ sudo yum install docker-ce-<VERSION>
启动 Docker。
```

#### rpm方式进行安装
```
 $ wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-<VERSION>.rpm
 $ sudo yum install /path/to/package.rpm
 $ sudo systemctl start docker
```

#### 二进制方式安装
```
 $ wget https://download.docker.com/linux/static/stable/x86_64/docker-18.06.1-ce.tgz
 $ tar -zxvf docker-18.06.1-ce.tgz
 $ cp docker/docker /usr/bin/docker
 $ service docker restart
 $ service docker status 
 $ systemctl enable docker
 $ docker version
```
### 升级 DOCKER CE
```
 $ yum -y upgrade 
```

### 卸载 Docker CE
```
 $ sudo yum remove docker-ce
 $ sudo rm -rf /var/lib/docker
```

## linux安装后步骤

### 以非root用户管理docker
```
 $ groupadd docker
 $ usermod -aG dockere $USER
```

### docker开启自启动
```
centos7:
 $ systemctl enable docker

centos6:
 $ chkconfig docker on
```
### 开启ip转发
```
 $ sysctl -w net.ipv4.ip_forward=1
 $ vim /etc/sysctl.conf
   net.ipv4.ip_forward = 1
```
### 指定dns服务器
```
 $ vim /etc/docker/daemon.json
   {
    	"dns":["8.8.8.8", "8.8.4.4"]
   }
 $ sudo service docker restart
```

# 参考
* [https://docs.docker-cn.com](https://docs.docker-cn.com)
* [http://www.dockerinfo.net/document](http://www.dockerinfo.net/document)