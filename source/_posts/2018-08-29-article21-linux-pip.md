---
layout: post
title: linux下pip安装的几种方式
author: owelinux
categories: linux
tags: linux
excerpt: linux下pip安装的几种方式
mathjax: true
abbrlink: de6c7712
date: 2018-08-29 17:37:54
---

* content
{:toc}

# linux下pip安装的几种方式

## 安装方式1
```
wget  http://python-distribute.org/distribute_setup.py  
sudo python distribute_setup.py  
wget  https://github.com/pypa/pip/raw/master/contrib/get-pip.py  
sudo python get-pip.py
```  
## 安装方式2
```
wget https://pypi.python.org/packages/source/p/pip/pip-1.3.1.tar.gz --no-check-certificate   
tar xvf pip-1.3.1.tar.gz  
python pip-1.3.1/setup.py install  
```
## 安装方式3
```
wget https://bootstrap.pypa.io/get-pip.py  
python get-pip.py  
```

## 设置其他源
```
vim ~/.pip/pip.conf
[global]

index-url=http://pypi.hustunique.com/simple

其他源：index-url=http://mirrors.tuna.tsinghua.edu.cn/pypi/simple  这个比较快一点

```

## 参考
> * [https://pypi.Python.org/pypi/setuptools#unix-wget](https://pypi.Python.org/pypi/setuptools#unix-wget)
> * [https://pip.pypa.io/en/latest/installing.html](https://pip.pypa.io/en/latest/installing.html)
> * [https://blog.csdn.net/jinruoyanxu/article/details/53947570](https://blog.csdn.net/jinruoyanxu/article/details/53947570)