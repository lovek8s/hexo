---
abbrlink: '0'
---

# 精简 Docker 镜像的技巧

精简 Docker 镜像的好处很多，不仅可以节省存储空间和带宽，还能减少安全隐患。优化镜像大小的手段多种多样，因服务所使用的基础开发语言不同而有差异。本文将介绍精简 Docker 镜像的几种通用方法。

## 精简 Docker 镜像大小的必要性
Docker 镜像由很多镜像层（Layers）组成（最多 127 层），镜像层依赖于一系列的底层技术，比如文件系统（filesystems）、写时复制（copy-on-write）、联合挂载（union mounts）等技术，你可以查看Docker 社区文档以了解更多有关 Docker 存储驱动的内容，这里就不再赘述技术细节。总的来说，Dockerfile 中的每条指令都会创建一个镜像层，继而会增加整体镜像的尺寸。

下面是精简 Docker 镜像尺寸的好处：

    1.减少构建时间
    2.减少磁盘使用量
    3.减少下载时间
    4.因为包含文件少，攻击面减小，提高了安全性
    5.提高部署速度
## 编写小容量镜像的Dockerfile的技巧

### 使用较小的基础镜像
优化基础镜像的方法就是选用合适的更小的基础镜像，常用的 Linux 系统镜像一般有 Ubuntu、CentOs、Alpine，其中 Alpine 更推荐使用。大小对比如下：alpine < ubuntu < debian < centos

另外可以选择适合更小的基础镜像
    
1、scratch 镜像（空镜像，只能用于构建其他镜像，比如你要运行一个包含所有依赖的二进制文件，如Golang 程序，可以直接使用 scratch 作为基础镜像。）
```
FROME scratch
ARG ARCH
ADD bin/pause-${ARCH} /pause
ENTRYPOINT ["/pause"]
```

2、busybox 镜像（镜像里可以包含一些常用的 Linux 工具，busybox 镜像是个不错选择，镜像本身只有 1.16M，非常便于构建小镜像）

### 将多个命令集放在一行
大家在定义 Dockerfile 时，如果太多的使用 RUN 指令，经常会导致镜像有特别多的层，镜像很臃肿，而且甚至会碰到超出最大层数（127层）限制的问题，遵循 Dockerfile 最佳实践，我们应该把多个命令串联合并为一个 RUN（通过运算符&&和/ 来实现），每一个 RUN 要精心设计，确保安装构建最后进行清理，这样才可以降低镜像体积，以及最大化的利用构建缓存。。以Nginx的官方的Dockerfile为例：
```
FROM debian:jessie
MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"
ENV NGINX_VERSION 1.11.3-1~jessie
RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
	&& echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
						ca-certificates \
						nginx=${NGINX_VERSION} \
						nginx-module-xslt \
						nginx-module-geoip \
						nginx-module-image-filter \
						nginx-module-perl \
						nginx-module-njs \
						gettext-base \
	&& rm -rf /var/lib/apt/lists/*
# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
```

### 使用多阶段构建
Dockerfile 中每条指令都会为镜像增加一个镜像层，并且你需要在移动到下一个镜像层之前清理不需要的组件。实际上，有一个 Dockerfile 用于开发（其中包含构建应用程序所需的所有内容）以及一个用于生产的瘦客户端，它只包含你的应用程序以及运行它所需的内容。这被称为“建造者模式”。Docker 17.05.0-ce 版本以后支持多阶段构建。使用多阶段构建，你可以在 Dockerfile 中使用多个 FROM 语句，每条 FROM 指令可以使用不同的基础镜像，这样您可以选择性地将服务组件从一个阶段 COPY 到另一个阶段，在最终镜像中只保留需要的内容。

下面是一个使用 COPY --from 和 FROM … AS … 的 Dockerfile：
```
# Compile
FROME golang:1.9.0 AS builder
WORKDIR /go/src/v9.git...com/.../k8s-monitor
COPY . .
WORKDIR /go/src/v9.git...com/.../k8s-monitor
RUN make build && mv k8s-monitor /root

# Package
# Use scratch image
FROM scratch
WORKDIR /root/
COPY --from=builder /root .
EXPOSE 800
CMD ["/root/k8s-monitor"]
```

### 使用缓存加快构建速度

Docker 在 build 镜像的时候，如果某个命令相关的内容没有变化，会使用上一次缓存（cache）的文件层，在构建业务镜像的时候可以注意下面两点：

* 不变或者变化很少的体积较大的依赖库和经常修改的自有代码分开；

* 因为 cache 缓存在运行 Docker build 命令的本地机器上，建议固定使用某台机器来进行 Docker build，以便利用 cache。

```
FROM openjdk:8-jre-alpine
COPY app/BOOT_INF/lib /app/BOOT_INF/lib/
COPY app/org /app/org
COPY app/META_INF /app/META_INF
COPY app/BOOT_INT/classes   /app/BOOT_INT/classes
EXPOSE 8080
CMD ["java","-cp","/app","org.springframework.boot.loader.JarLauncher"]
```
Dockerfile 我们把应用的内容分成 4 个部分 COPY 到镜像里面：其中前面 3 个基本不变，第 4 个是经常变化的自有代码。最后一行是解压缩后，启动 spring boot 应用的方式。

### 清理缓存和不必要的文件

（1）在执行 apt-get install -y 时增加选项 --no-install-recommends ，可以不用安装建议性（非必须）的依赖，也可以在执行 apk add 时添加选项--no-cache 达到同样效果；

（2）执行 yum install -y 时候， 可以同时安装多个工具，比如 yum install -y gcc gcc-c++ make …。将所有 yum install 任务放在一条 RUN 命令上执行，从而减少镜像层的数量；

（3）组件的安装和清理要串联在一条指令里面，如 apk --update add php7 && rm -rf /var/cache/apk/* ，因为 Dockerfile的每条指令都会产生一个文件层，如果将 apk add … 和 rm -rf … 命令分开，清理无法减小apk命令产生的文件层的大小。 Ubuntu或 Debian可以使用 rm -rf /var/lib/apt/lists/* 清理镜像中缓存文件；CentOS 等系统使用 yum clean all 命令清理；alpine系统可使用apt-get purge -y package_name &&  apt-get autoremove && apt-get clean 来清除apt的缓存
 
 (4) 删除不必要的文档和日志：rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* 和删除log文件：find /var | grep '\.log$' | xargs rm -v

### 压缩镜像
Docker 自带的一些命令还能协助压缩镜像，比如 export 和 import。
可以使用如下命令：docker export image_name | docker import - new_image_name。

## 参考文档
[https://zhuanlan.zhihu.com/p/42815689](https://zhuanlan.zhihu.com/p/42815689)