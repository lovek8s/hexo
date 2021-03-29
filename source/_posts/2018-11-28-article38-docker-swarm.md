---
layout: post
title: Docker Swarm 学习笔记总结
author: owelinux
categories: linux
tags: linux
excerpt: Docker Swarm 学习笔记总结
mathjax: true
abbrlink: 3227c071
date: 2018-11-28 18:23:54
---

* content
{:toc}

# Docker Swarm 学习笔记总结 

## Swarm 介绍
Docker Swarm是Docker官方提供的集群工具。它可以将一些关联的Docker主机转变成一个虚拟Docker主机。因为Docker Swarm符合Docker API的标准,任何已经可以与Docker守护进程通信的工具都可以使用Swarm来透明地扩展到多个主机。支持工具包括:

*    Dokku
*    Docker Compose
*    Docker Machine
*    Jenkins


## Swarm 架构
Swarm 是用来被用来管理 Docker 集群的，所以单个 Docker host 是整个集群的基础。Swarm 自身可以有两种安装方式，一种是当成普通的 Docker 容器来安装，一种是当成一个简单的应用被安装在一台虚拟机或者物理机上。它的架构图如下：

![Swarm 架构图](https://www.ibm.com/developerworks/cn/cloud/library/1511_zhangyq_dockerswarm/index1869.png)


所有的 Docker node 都会被当成一个调度候选对象。类似于 OpenStack 中的 compute node.

## Swarm 集群功能

### Swarm 调度器

调度是集群中十分重要的功能，Swarm目前支持三种调度策略：Spread、Binpack和random。
在执行swarm manage启动管理服务时，可通过--strategy参数指定调度策略，默认是：spread。

三种调度策略的优缺点：

* spread： 配置相同情况下，选择一个正在运行的容器数量最少的那个节点，平摊容器到各个节点。

* binpack：尽可能将所有容器放在一台节点上运行，尽量少用节点，避免容器碎片化。

* random： 直接随机分配，不考虑集群节点状态，方便进行测试使用。

### Swarm 过滤器
Swarm 过滤器（filter）可以实现特定的容器分配到特点的节点上。目前支持物种过滤器：Constraint、Affinity、Port、Dependency、Health。

* Constraint 过滤器： 绑定到节点的键值对，相当于给节点打标签。比如在启动Docker服务时，指定某个节点颜色为 red。

* Affinity 过滤器：允许用户在启动一个容器的时候，让它分配到某个已有容器的节点上。

* 其他过滤器也类似，通过-e affinity:image==<name or id>选择拥有指定镜像的节点，通过-e affinity:lael_name==value来选择拥有指定标签的容器所允许的节点。 

### Swarm 服务发现

通过不同的路径来选择特定的服务发现后端机制：

* token://<token>: 使用Docker Hub提供的服务，适用于公网；
* file://pah/to/file：使用本地文件，需手动管理；
* consul://<ip>/<path>：使用consul服务，私有环境；
* etcd://<ip1>,<ip2>,<ip3>/<path>：使用etcd服务，私有环境；
* zk://<ip1>,<ip2>,<ip3>/<path>：使用zk服务，私有环境；
* [nodes://]<ip1>,<ip2>,<ip3>：手动指定集群中节点地址，方便进行服务测试。

## Swarm 集群实战

### 安装Dcoker Swarm的方式
安装Docker Swarm有两种方式：

* 直接以swarm为镜像模板启动容器；
* 在系统中安装swarm的二进制可执行文件。

官网也列举出了这两种方法的优缺点：

以swarm镜像启动容器：

* 无需在系统中安装可执行的二进制文件；
* 用docker run命令每次都可以获取并运行最近版本的镜像；
* 容器是Swarm与主机环境相隔离，无需维护shell的路径和环境。

在系统中安装swarm：

* Swarm项目的开发者在测试代码变更的过程中，无需在运行该二进制文件前进行容器化(“containerizing”)操作。

### 集群创建步骤
创建一个Swarm集群的第一步是从网上拉取Docker Swarm镜像。然后,你可以使用Docker配置Swarm manager和所有节点运行Docker Swarm。步骤:

* 在每个节点上打开一个TCP端口用于跟Swarm manager通信
* 在每个节点上安装Docker
* 创建和管理TLS证书以保护集群

### 集群部署环境

    Docker01 和 Docker02 分别对应 manager0 和 manager1；
    Docker04 和 Docker05 分别对应 node0 和 node1；
    Docker03 对应 consul0；

配置ssl证书及安装docker服务
```
mkdir -p /etc/docker/certs.d/DomainName:Port
cp ca.crt /etc/docker/certs.d/DomainName:Port/
service docker restart
```

创建Swarm集群：
```
 # 在高可用的Swarm集群中创建主管理者
 # 操作对象 manager0 和 consul0
 # <manager0_ip> 和 <consul_ip>相同
 docker run -d -p 4000:4000 swarm manage -H :4000 --replication --advertise <manager0_ip>:4000 consul://<consul_ip>:8500

 # 操作对象 manager1
 docker run -d -p 4000:4000 swarm manage -H :4000 --replication --advertise <manager1_ip>:4000 consul://172.30.0.161:8500

 # 操作对象 node0 和 node1
 docker run -d swarm join --advertise=<node_ip>:2375 consul://<consul_ip>:8500
```

集群使用：
```
 # 操作对象 manager0 和 consul0
 docker -H :4000 info

 # 在Swarm集群中运行应用
 docker -H :4000 run hello-world

 # 查询Swarm集群的哪个节点在运行该应用
 docker -H :4000 ps
- 测试Swarm集群的故障；
 # 获取swarm容器的id或名称
 # 操作对象 manager0
 docker ps

 # 删除或关闭当前的主管理者 manager0
 docker rm -f <id_name>

 # 创建或启动Swarm集群管理者 manager0
 docker run -d -p 4000:4000 swarm manage -H :4000 --replication --advertise <manager0_ip>:4000 consul://<consul_ip>:8500

 # 查看该容器的日志
 sudo docker logs <id_name>

 # 获取集群管理者和节点的信息
 docker -H :4000 info
```
## 个人总结

### Swarm 上的容器选择

* 适合无状态服务：web服务、反向代理、采集器等
* 不适合有状态服务：数据库、redis、zk等
### 设置Docker仓库
* 指明Docker仓库地址
* 私有仓库增加参数：--with-registry-auth
* 使用tag进行版本上线及回滚

### 改造无状态化应用容器
* 采用共享存储挂载方式

### 日志采集服务
集中式的日志和指标是使用分布式文件系统的必须项，如ELK，Graphana，Graylog 等等。

这里有许多可选项，有开源项目，也有SaaS类服务。这些打造和整合成可靠的服务是复杂且艰难的。建议先使用云端服务（如Loggly, Logentries）, 当成本上涨的时候，再开始架设自己的日志收集服务。
例：ELK 栈日志处理配置:
```
docker service update \ --log-driver gelf \
--log-opt gelf-address=udp://monitoring.example.com:12201 \
--log-opt tag=example-tag \
example-service
```

### 创建可附加的网络
记得使用它，否则无法在Docker Swarm下一条命令跑起一个容器。这是Docker1.13+新功能。如果使用旧版本的Docker, 最好升级下。

代码：
```
docker network create --driver=overlay --attachable core
```

### 增加环境变量
如果创建Docker镜像的时候，遵循了最佳实践原则（https://rock-it.pl/how-to-writ ... iles/），允许在运行的时候通过环境变量设置一切配置项，那么把应用迁到Swarm的过程完全没有问题。

例，有用的命令：

```
docker service create \

--env VAR=VALUE \
--env-file FILENAME \
...

docker service update \

--env-add VAR=NEW_VALUE \
--env-rm VAR \
..
```

下一个级别就是使用非公开的API挂载文件像挂载秘钥那样（Authorized keys, SSL certs 等）。作者暂时还未使用此功能，不能详述，但这个功能特性绝对值得思考和使用。

### 设置适当实例和批量更新
保持适当数量的实例，以应对高流量和实例或者节点不可用的情况。同时太多的实例数也会占用CPU和内存，并且导致争抢CUP资源。

update-parallelism的默认值是1，默认只有一个实例在运行。但这个更新速度太慢了，建议是 replicas / 2。

相关命令：

```
docker service update \

--update-parallelism 10 \
webapp

You can scale multiple services at once
docker service scale redis=1 nginx=4 webapp=20

Check scaling status
docker service ls

Check details of a service (without stopped containers)
docker service ps webapp | grep -v "Shutdown"
```

### 把Swarm配置保存为代码
最好使用Docker Compose v3版本的语法（https://docs.docker.com/compos ... eploy）。

他允许使用代码指定几乎所有的服务选项。作者在开发的时候使用 Docker-compose.yml，在生产环境（swarm）配置使用 Docker-compose.prod.yml . 部署Docker-compose文件中所描述的服务，需要Docker stack deploy 命令（属于新版本 Stack命令集合中的一部分[https://docs.docker.com/engine ... tack/]）

Docker compose v3例子：

```
docker-compose.prod.yml
version: '3'

services:

webapp:
image: registry.example.com/webapp
networks:
- ingress
deploy:
replicas: ${WEBAPP_REPLICAS}
mode: replicated
restart_policy:
condition: on-failure

proxy:
image: registry.example.com/webapp-nginx-proxy
networks:
- ingress
ports:
- 80:80
- 443:443
deploy:
replicas: ${NGINX_REPLICAS}
mode: replicated
restart_policy:
condition: on-failure

networks:

ingress:
external: true
```

部署的例子（创建或者更新服务）：

```
export NGINX_REPLICAS=2 WEBAPP_REPLICAS=5

docker login registry.example.com

docker stack deploy \

-c docker-compose.prod.yml\
--with-registry-auth \
frontend
```

提示：Docker-compose文件支持环境变量 (${VARIABLE}), 所以，可以动态调整配置作为测试等。

### 设置限制
就经验而言，可以为所有服务设置CPU使用限制。当某一个容器应用占用掉所有主机资源时，此限制可以避免这种情况发生。

当想把所有容器均匀地发布在所有主机上或是想确保有足够的资源来响应操作时，需使用Reserve-cpu这个参数。

例如：
```
docker service update --limit-cpu 0.25
--reserve-cpu 0.1
webapp
```

### 监控连接
曾经在Swarm网络上遇到过一些问题。很多次所有的流量都被路由到同一个容器实例上，而同时有9个容器实例正常且健康的。这种情况下——即流量持续导到一个实例上，做扩容或者缩容操作的时候，加上这个参数--endpoint-mode 。

## 参考文档
[https://www.ibm.com/developerworks/cn/cloud/library/1511_zhangyq_dockerswarm/index.html](https://www.ibm.com/developerworks/cn/cloud/library/1511_zhangyq_dockerswarm/index.html)

[http://dockone.io/article/1486](http://dockone.io/article/1486)

[http://dockone.io/article/2318](http://dockone.io/article/2318)

[https://rock-it.pl/my-experience-with-docker-swarm-when-you-need-it/](https://rock-it.pl/my-experience-with-docker-swarm-when-you-need-it/)

[Docker技术入门于实战~Swarm章节]()