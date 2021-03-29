---
layout: post
title: linux常用命令lsof详解
author: owelinux
categories: linux
tags: linux
excerpt: linux常用命令lsof详解.
mathjax: true
abbrlink: b85c2d0
date: 2018-07-28 09:35:54
---

* content
{:toc}

# linux常用命令lsof详解

## lsof 简介  
lsof（list open files）是一个列出当前系统打开文件的工具。在linux环境下，任何事物都以文件的形式存在，通过文件不仅仅可以访问常规数据，还可以访问网络连接 和硬件。所以如传输控制协议 (TCP) 和用户数据报协议 (UDP) 套接字等，系统在后台都为该应用程序分配了一个文件描述符，无论这个文件的本质如何，该文件描述符为应用程序与基础操作系统之间的交互提供了通用接口。因为应用程序打开文件的描述符列表提供了大量关于这个应用程序本身的信息，因此通过lsof工具能够查看这个列表对系统监测以及排错将是很有帮助的。 

可以列出被进程所打开的文件的信息。被打开的文件可以是：
> * 1.普通的文件
> * 2.目录  
> * 3.网络文件系统的文件
> * 4.字符设备文件  
> * 5.(函数)共享库  
> * 6.管道，命名管道 
> * 7.符号链接
> * 8.底层的socket字流，网络socket，unix域名socket
> * 9.在linux里面，大部分的东西都是被当做文件的…..还有其他很多
## lsof 常用参数
> * lsof  filename 显示打开指定文件的所有进程 
> * lsof -a 表示两个参数都必须满足时才显示结果 
> * lsof -c string   显示COMMAND列中包含指定字符的进程所有打开的文件 
> * lsof -u username  显示所属user进程打开的文件 
> * lsof -g gid 显示归属gid的进程情况 
> * lsof +d /DIR/ 显示目录下被进程打开的文件 
> * lsof +D /DIR/ 同上，但是会搜索目录下的所有目录，时间相对较长 
> * lsof -d FD 显示指定文件描述符的进程 
> * lsof -n 不将IP转换为hostname，缺省是不加上-n参数 
> * lsof -i 用以显示符合条件的进程情况 
> * lsof -i[46] [protocol][@hostname|hostaddr][:service|port]  
> * lsof +L/-L 打开或关闭文件的连结数计算，当+L没有指定时，所有的连结数都会显示(默认)；若+L后指定数字，则只要连结数小于该数字的信息会显示；连结数会显示在NLINK列。
例如：+L1将显示没有unlinked的文件信息；+aL1，则显示指定文件系统所有unlinked的文件信息。-L 默认参数，其后不能跟数字，将不显示连结数信息lsof +L1

## lsof 使用实例
### 1.列出所有打开的文件:
```
lsof
备注: 如果不加任何参数，就会打开所有被打开的文件，建议加上一下参数来具体定位
```
### 2. 查看谁正在使用某个文件
```
lsof   /filepath/file
```
### 3.递归查看某个目录的文件信息
```
lsof +D /filepath/filepath2/
备注: 使用了+D，对应目录下的所有子目录和文件都会被列出
```
### 4. 比使用+D选项，遍历查看某个目录的所有文件信息 的方法
```
lsof | grep ‘/filepath/filepath2/’
```
### 5. 列出某个用户打开的文件信息
```
lsof  -u username
```
### 6. 列出某个程序所打开的文件信息
```
lsof -c mysql
备注: -c 选项将会列出所有以mysql开头的程序的文件，其实你也可以写成 lsof | grep mysql, 但是第一种方法明显比第二种方法要少打几个字符了
```
### 7. 列出多个程序多打开的文件信息
```
lsof -c mysql -c apache
```
### 8. 列出某个用户以及某个程序所打开的文件信息
```
lsof -u test -c mysql
```
### 9. 列出除了某个用户外的被打开的文件信息
```
lsof   -u ^root
备注：^这个符号在用户名之前，将会把是root用户打开的进程不让显示
```
### 10. 通过某个进程号显示该进行打开的文件
```
lsof -p 1
```
### 11. 列出多个进程号对应的文件信息
```
lsof -p 123,456,789
```
### 12. 列出除了某个进程号，其他进程号所打开的文件信息
```
lsof -p ^1
```
### 13 . 列出所有的网络连接
```
lsof -i
```
### 14. 列出所有tcp 网络连接信息
```
lsof  -i tcp
```
### 15. 列出所有udp网络连接信息
```
lsof  -i udp
```
### 16. 列出谁在使用某个端口
```
lsof -i:3306
```
### 17. 列出谁在使用某个特定的udp端口
```
lsof -i udp:55
lsof -i tcp:80
```
### 18. 列出某个用户的所有活跃的网络端口
```
lsof  -a -u test -i
```
### 19. 列出所有网络文件系统
```
lsof -N
```
### 20.域名socket文件
```
lsof -u
```
### 21.某个用户组所打开的文件信息
```
lsof -g 5555
```
### 22. 根据文件描述列出对应的文件信息
```
lsof -d description(like 2)
```
### 23. 根据文件描述范围列出文件信息
```
lsof -d 2-3
```
### 24.搜索打开的网络连接
```
lsof –i@10.65.64.23
```
### 25.寻找本地断开的打开文件 
```
lsof –a +L1 /data 
```
### 26.恢复删除的文件
```
a.使用lsof来查看当前是否有进程打开/var/logmessages文件，如下：  
# lsof |grep /var/log/messages 
syslogd   1283      root    2w      REG        3,3  5381017    1773647 /var/log/messages (deleted)  

PID 1283（syslogd）打开文件的文件描述符为 2

b.我们可以在 /proc/1283/fd/2 （fd下的每个以数字命名的文件表示进程对应的文件描述符）中查看相应的信息，如下：  
# head -n 10 /proc/1283/fd/2 
Aug  4 13:50:15 holmes86 syslogd 1.4.1: restart. 
Aug  4 13:50:15 holmes86 kernel: klogd 1.4.1, log source = /proc/kmsg started. 
Aug  4 13:50:15 holmes86 kernel: Linux version 2.6.22.1-8 (root@everestbuilder.linux-ren.org ) (gcc version 4.2.0) #1 SMP Wed Jul 18 11:18:32 EDT 2007 
Aug  4 13:50:15 holmes86 kernel: BIOS-provided physical RAM map: 
Aug  4 13:50:15 holmes86 kernel:  BIOS-e820: 0000000000000000 - 000000000009f000 (usable) 
Aug  4 13:50:15 holmes86 kernel:  BIOS-e820: 000000000009f000 - 00000000000a0000 (reserved) 
Aug  4 13:50:15 holmes86 kernel:  BIOS-e820: 0000000000100000 - 000000001f7d3800 (usable) 
Aug  4 13:50:15 holmes86 kernel:  BIOS-e820: 000000001f7d3800 - 0000000020000000 (reserved) 
Aug  4 13:50:15 holmes86 kernel:  BIOS-e820: 00000000e0000000 - 00000000f0007000 (reserved) 
Aug  4 13:50:15 holmes86 kernel:  BIOS-e820: 00000000f0008000 - 00000000f000c000 (reserved)  

/proc/1283/fd/2 文件内容就是删除数据中的信息

c.使用 I/O 重定向将其复制到文件中，如:  
# cat /proc/1283/fd/2 > /var/log/messages   

对于许多应用程序，尤其是日志文件和数据库，这种恢复删除文件的方法非常有用。

在 Solaris 中查找删除的文件 
# lsof -a -p 8663 -d ^txt
COMMAND  PID   USER   FD   TYPE        DEVICE SIZE/OFF    NODE NAME
httpd   8663 nobody  cwd   VDIR         136,8     1024       2 /
httpd   8663 nobody    0r  VCHR          13,2          6815752 /devices/pseudo/mm@0:null
httpd   8663 nobody    1w  VCHR          13,2          6815752 /devices/pseudo/mm@0:null
httpd   8663 nobody    2w  VREG         136,8      185  145465 / (/dev/dsk/c0t0d0s0)
httpd   8663 nobody    4r  DOOR                    0t0      58 /var/run/name_service_door
                        (door to nscd[81]) (FA:->0x30002b156c0)
httpd   8663 nobody   15w  VREG         136,8      185  145465 / (/dev/dsk/c0t0d0s0)
httpd   8663 nobody   16u  IPv4 0x300046d27c0      0t0     TCP *:80 (LISTEN)
httpd   8663 nobody   17w  VREG         136,8        0  145466                                                          /var/apache/logs/access_log
httpd   8663 nobody   18w  VREG         281,3        0 9518013 /var/run (swap) 
使用 -a 和 -d 参数对输出进行筛选，以排除代码程序段，"^"是取反的意思。Name 列显示出，其中的两个文件（FD 2 和 15）使用磁盘名代替了文件名，并且它们的类型为 VREG（常规文件）。在 Solaris 中，删除的文件将显示文件所在的磁盘的名称。通过这个线索，就可以知道该 FD 指向一个删除的文件。实际上，查看 /proc/8663/fd/15 就可以得到所要查找的数据。
```
### 27.lsof 修改句柄限制
```
# lsof -n|awk '{print $2}'|sort|uniq -c |sort -nr|more   
        131 24204  
         57 24244  
         57 24231  
         56 24264  
其中第一列是打开的文件句柄数量，第二行是进程号。得到进程号后，我们可以通过ps命令得到进程的详细内容。
#ps -aef|grep 24204  
 mysql    24204 24162 99 16:15 ?        00:24:25 /usr/sbin/mysqld  
查看得知是mysql进程打开最多文件句柄数量。但是他目前只打开了131个文件句柄数量，远远底于系统默认值1024。
但是如果系统并发特别大，尤其是squid服务器，很有可能会超过1024。这时候就必须要调整系统参数，以适应应用变化。Linux关于打开文件句柄数量，有硬性限制和软性限制。可以通过ulimit来设定这两个参数。方法如下，以root用户运行以下命令：
#ulimit -HSn 4096  
```
## 参考：
> * http://czmmiao.iteye.com/blog/1734384
> * https://blog.csdn.net/kozazyh/article/details/5495532
