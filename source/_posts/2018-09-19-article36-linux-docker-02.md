---
layout: post
title: Docker 系列02-docker常用命令
author: owelinux
categories: linux 容器与虚拟化
tags: linux  docker
excerpt: Docker 系列02-docker常用命令
mathjax: true
abbrlink: '88e80668'
date: 2018-09-19 10:29:54
---

* content
{:toc}

# Docker 系列02-docker常用命令

## Dockerfile

定义一个Dockerfile文件
```
# 将官方 Python 运行时用作父镜像
FROM python:2.7-slim

# 将工作目录设置为 /app
WORKDIR /app

# 将当前目录内容复制到位于 /app 中的容器中
ADD . /app

# 安装 requirements.txt 中指定的任何所需软件包
RUN pip install -r requirements.txt

# 使端口 80 可供此容器外的环境使用
EXPOSE 80

# 定义环境变量
ENV NAME World

# 在容器启动时运行 app.py
CMD ["python", "app.py"]
```



构建镜像
```
docker build -t friendlyname .
```

启动镜像，并且映射本地4000到容器端口80
```
docker run -p 4000:80 friendlyname  
```
后台方式启动镜像
```
docker run -d -p 4000:80 friendlyname
```

查看所有正在运行的容器的列表
```         
docker ps
```

停止指定的容器
```
docker stop <hash>
```

查看所有容器的列表
```
docker ps -a
```

强制关闭指定的容器
```
docker kill <hash>
```

删除指定的容器
```
docker rm <hash>
```

删除所有容器
```
docker rm $(docker ps -a -q)
```

显示所有镜像
```
docker images -a
```

删除指定的镜像
```
docker rmi <imagename>
```

删除所有镜像
```
docker rmi $(docker images -q)
```

登录docker
```
docker login             
```

镜像打标签
```
docker tag <image> username/repository:tag
```

将打完标签的镜像上传
```
docker push username/repository:tag
```

## swarm

定义一个docker-compose.yml
```
version: "3.1"
services:
  web:
    image: username/rep:tag
    deploy:
      replicas: 4
      resources:
        limits:
          cpus: "0.1"
          memory: 50M
      restart_policy:
        condition: on-failure
    ports:
      - "80:80"
    networks:
      - webnet
networks:
  webnet:
```

初始话swarm管理节点
```
docker swarm init
```

列出此 Docker 主机上所有正在运行的应用
```
docker stack ls 
```

运行指定的 Compose 文件
```             
docker stack deploy -c <composefile> <appname>
```

列出与应用关联的服务
```
docker stack services <appname>
```

列出与应用关联的正在运行的容器
```
docker stack ps <appname>
```

清除应用
```
docker stack rm <appname>                             #
```

## swarm集群

swarm 是一组运行 Docker 并且已加入集群中的机器。执行此操作后，您可以继续运行已使用的 Docker 命令，但现在它们在集群上由 swarm 管理节点执行。 swarm 中的机器可以为物理或虚拟机。加入 swarm 后，可以将它们称为节点。

swarm 管理节点可以使用多项策略来运行容器，例如“最空的节点”– 这将使用容器填充使用最少的机器。或“全局”，这将确保每台机器恰好获得指定容器的一个实例。您可以指示 swarm 管理节点使用 Compose 文件中的这些策略，就像您已使用的策略一样。

swarm 管理节点是 swarm 中可以执行命令或授权其他机器加入 swarm 作为工作节点的唯一机器。工作节点仅用于提供功能，并且无权告知任何其他机器它可以做什么和不能做什么。

到目前为止，您已在本地机器上以单主机模式使用 Docker。但是，也可以将 Docker 切换到 swarm mode，并且这可以实现 swarm 的使用。即时启用 swarm mode 可以使当前机器成为 swarm 管理节点。从那时起，Docker 将在您要管理的 swarm 上运行您执行的命令，而不是仅在当前机器上执行命令。


创建 VM（Mac、Win7、Linux）
```
docker-machine create --driver virtualbox myvm1
```

创建 VM (Win10)
```
docker-machine create -d hyperv --hyperv-virtual-switch "myswitch" myvm1
```

查看有关节点的基本信息
```
docker-machine env myvm1
```

列出 swarm 中的节点
```
docker-machine ssh myvm1 "docker node ls"
```

检查节点
```
docker-machine ssh myvm1 "docker node inspect <node ID>"
```

查看加入令牌
```
docker-machine ssh myvm1 "docker swarm join-token -q worker"
```

打开与 VM 的 SSH 会话；输入“exit”以结束会话
```
docker-machine ssh myvm1
```

使工作节点退出 swarm
```
docker-machine ssh myvm2 "docker swarm leave"
```

使主节点退出，终止 swarm
```
docker-machine ssh myvm1 "docker swarm leave -f"
```

启动当前未运行的 VM
```
docker-machine start myvm1
```

停止所有正在运行的 VM
```
docker-machine stop $(docker-machine ls -q)   
```

删除所有 VM 及其磁盘镜像
```            
docker-machine rm $(docker-machine ls -q)
```

将文件复制到节点的主目录
```
docker-machine scp docker-compose.yml myvm1:~
```

部署应用
```
docker-machine ssh myvm1 "docker stack deploy -c <file> <app>"
```

## docker 网络配置

列出所有网络
```
docker network ls
```

通过网络查找容器ip地址
```
docker network inspect bridge
```

通过断开容器来从网络中删除容器
```
docker network disconnect bridge <dockername>
```

创建自定义桥接网络
```
docker network create -d bridge my_bridge
```

指定容器使用的网络
```
docker  run -d --net=my_bridge --name db training/postgres
```

查看容器连接位置
```
docker inspect --format='{{json .NetworkSettings.Networks}}'  db
```

获取容器ip地址
```
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' db
```

连接容器网络
```
docker network connect my_bridge db
```

## docker 数据卷

添加数据卷
```
docker run -d -P --name web -v /webapp training/webapp python app.py

在容器内创建一个新卷/webapp
```

查看数据卷
```
docker inspect web

Source指定主机上的位置并 Destination指定容器内的卷位置。RW显示卷是否为读/写。
```

将主机目录挂在为数据卷
```
docer run -d -P --name web -v /src/webapp:/webapp training/webapp python app.py

主机目录/src/webapp,容器目录/webapp;container-dir必须始终是绝对路径
```

查找空闲卷
```
docker volume ls -f dangling=true
```

删除卷
```
docker volume rm <volume name>
```

备份，还原或迁移数据卷
```
docker run --rm --volumes-from dbstore -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /dbdata

docker run -v /dbdata --name dbstore2 ubuntu /bin/bash

docker run --rm --volumes-from dbstore2 -v $(pwd):/backup ubuntu bash -c "cd /dbdata && tar xvf /backup/backup.tar --strip 1"
```

删除所有未使用的卷
```
docker volume prune
```


# 参考

* [https://docs.docker-cn.com](https://docs.docker-cn.com)