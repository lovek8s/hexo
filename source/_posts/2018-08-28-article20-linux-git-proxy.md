---
layout: post
title: git部署及常用配置
author: owelinux
categories: linux
tags: linux  git
excerpt: git部署及常用配置
mathjax: true
abbrlink: 2ad8fd2a
date: 2018-08-28 17:37:54
---

* content
{:toc}

# git部署及常用配置

## 安装git

### 在 Linux 上安装：
```
$ sudo yum install git
```

### 在Mac上安装：

[官方下载](http://git-scm.com/download/mac)

### 在 Windows 上安装：
* a.[官方下载](http://git-scm.com/download/win)
* b.[GitHub for Windows](http://windows.github.com)


### 从源代码安装：
```
# 最小化的依赖包来编译和安装 Git 的二进制版：
$ sudo yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel

# 为了能够添加更多格式的文档（如 doc, html, info），你需要安装以下的依赖包：
$ sudo yum install asciidoc xmlto docbook2x

# 编译并安装：
$ tar -zxf git-2.0.0.tar.gz
$ cd git-2.0.0
$ make configure
$ ./configure --prefix=/usr
$ make all doc info
$ sudo make install install-doc install-html install-info
```

## 初次运行 Git 前的配置
Git 自带一个 git config 的工具来帮助设置控制 Git 外观和行为的配置变量。 这些变量存储在三个不同的位置：

*  /etc/gitconfig 文件: 包含系统上每一个用户及他们仓库的通用配置。 如果使用带有 --system 选项的 git config 时，它会从此文件读写配置变量。

* ~/.gitconfig 或 ~/.config/git/config 文件：只针对当前用户。 可以传递 --global 选项让 Git 读写此文件。

* 当前使用仓库的 Git 目录中的 config 文件（就是 .git/config）：针对该仓库。

每一个级别覆盖上一级别的配置，所以 .git/config 的配置变量会覆盖 /etc/gitconfig 中的配置变量。

在 Windows 系统中，Git 会查找 $HOME 目录下（一般情况下是 C:\Users\$USER）的 .gitconfig 文件。 Git 同样也会寻找 /etc/gitconfig 文件，但只限于 MSys 的根目录下，即安装 Git 时所选的目标位置。

详细配置请参考：[https://git-scm.com/docs/git-config](https://git-scm.com/docs/git-config)

### 用户信息
```
$ git config --global user.name "John Doe"

$ git config --global user.email johndoe@example.com
```

### 文本编辑器
```
$ git config --global core.editor emacs/vim/nodepad++
```

### 代理配置
```
$ git config --global http.proxy socks5://127.0.0.1:1080

$ git config --global https.proxy socks5://127.0.0.1:1080

$ git config --global http.sslVerify false
``` 

## 报错解决
```
$ git clone https://github.com/xxxx/xxxx.git
Cloning into 'xxxx...
fatal: unable to access 'https://github.com/xxxx/xxxx.git': OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to github.com:443

如遇到以上错误，是由于连接不上远程git仓库，配置代理即可解决！

```


## 参考
> * [https://git-scm.com/book/zh/v2](https://git-scm.com/book/zh/v2)