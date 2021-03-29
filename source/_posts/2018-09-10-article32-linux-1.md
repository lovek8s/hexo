---
layout: post
title: 'linux shell中&>file,2>&1,1>&2区别'
author: owelinux
categories: linux
tags: linux
excerpt: 'linux shell中&>file,2>&1,1>&2区别'
mathjax: true
abbrlink: 7c357ced
date: 2018-09-10 18:29:54
---

* content
{:toc}

# linux shell中&>file,2>&1,1>&2区别

shell中几个定义：

* 0：表示标准输入

* 1：表示标准输出

* 2：表示标准错误输出
* >：默认为标准输出重定向，与1>相同（替换）
* >>：表示标准输出重定向（追加）
* 2>&1：表示把标准错误输出 重定向到标准输出
* &>file：表示把标准输出和标准错误输出 都重定向到文件file中 

举例：

替换：
```
grep "aaa" filename > a.log
```

追加：
```
grep "bbb" filename >>b.log
```

2>&1:
```
grep "error" filename >/dev/null 2>&1
等价于
grep "error" filename >/dev/null 2>/dev/null
```

&>file:
```
grep "error" filename >/dev/null 
等价于
grep "error" filename >/dev/null 2>/dev/null
```