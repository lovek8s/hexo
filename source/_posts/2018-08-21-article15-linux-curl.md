---
layout: post
title: curl常用命令
author: owelinux
categories: linux
tags: linux
excerpt: curl常用命令
mathjax: true
abbrlink: 42b193b1
date: 2018-08-21 10:41:54
---

* content
{:toc}

# curl常用命令

## curl介绍
curl命令是一个利用URL规则在命令行下工作的文件传输工具。它支持文件的上传和下载，所以是综合传输工具，但按传统，习惯称curl为下载工具。作为一款强力工具，curl支持包括HTTP、HTTPS、ftp等众多协议，还支持POST、cookies、认证、从指定偏移处下载部分文件、用户代理字符串、限速、文件大小、进度条等特征。做网页处理流程和数据检索自动化，curl可以祝一臂之力。

## 语法
```
curl(选项)(参数)
```

## 选项       
* -a/--append	                    上传文件时，附加到目标文件 
* -A/--user-agent <string>	        设置用户代理发送给服务器   
* -anyauth	                        可以使用“任何”身份验证方法 
* -b/--cookie <name=string/file     cookie字符串或文件读取位置 
*      --basic	                    使用HTTP基本验证 
* -B/--use-ascii	                使用ASCII /文本传输 
* -c/--cookie-jar <file>	        操作结束后把cookie写入到这个文件中
* -C/--continue-at <offset>	        断点续转 
*                                                              
**-d/--data <data>	                HTTP POST方式传送数据** 
*      --data-ascii <data>	        以ascii的方式post数据 
*      --data-binary <data>	        以二进制的方式post数据
*      --negotiate	                使用HTTP身份验证 
*      --digest	                    使用数字身份验证 
*      --disable-eprt	            禁止使用EPRT或LPRT 
*      --disable-epsv	            禁止使用EPSV 
* -D/--dump-header <file>	        把header信息写入到该文件中 
*      --egd-file <file>	        为随机数据(SSL)设置EGD socket路径
*      --tcp-nodelay	            使用TCP_NODELAY选项 
* -e/--referer	                    来源网址 
* -E/--cert <cert[:passwd]>	        客户端证书文件和密码
*      --cert-type <type>	        证书文件类型
*      --key <key>	                私钥文件名
*      --key-type <type>	        私钥文件类型 
*      --pass <pass>	            私钥密码 
*      --engine <eng>	            加密引擎使用 
*      --cacert <file>	            CA证书 
*      --capath <directory>	        CA目录 
*      --ciphers <list>	            SSL密码 
*      --compressed	                要求返回是压缩的形势 
*      --connect-timeout    	    设置最大请求时间
*      --create-dirs	            建立本地目录的目录层次结构
*      --crlf	                    上传是把LF转变成CRLF 
* -f/--fail	                        连接失败时不显示http错误 
*      --ftp-create-dirs	        如果远程目录不存在，创建远程目录 
*      --ftp-method [multicwd/nocwd/singlecwd]	 控制CWD的使用
*      --ftp-pasv	                使用 PASV/EPSV 代替端口 
*      --ftp-skip-pasv-ip	        使用PASV的时候,忽略该IP地址 
*      --ftp-ssl	                尝试用 SSL/TLS 来进行ftp数据传输 
*      --ftp-ssl-reqd	            要求用 SSL/TLS 来进行ftp数据传输 
* -F/--form <name=content>	        模拟http表单提交数据
*      --form-string        	    模拟http表单提交数据 
* -g/--globoff	                    禁用网址序列和范围使用{}和[]   
*                                                              
**-G/--get	                        以get的方式来发送数据**
*                                                              
**-H/--header <line>	            自定义头信息传递给服务器**
*      --ignore-content-length	    忽略的HTTP头信息的长度 
* -i/--include	                    输出时包括protocol头信息 
*                                                              
**-I/--head	                        只显示请求头信息** 
* -j/--junk-session-cookies	        读取文件进忽略session cookie 
*      --interface <interface>	    使用指定网络接口/地址 
*      --krb4 <level>	            使用指定安全级别的krb4 
* -k/--insecure	                    允许不使用证书到SSL站点 
* -K/--config	                    指定的配置文件读取 
* -l/--list-only	                列出ftp目录下的文件名称 
*                                                              
**--limit-rate <rate>	        设置传输速度** 
*      --local-port<NUM>	        强制使用本地端口号 
*                                                              
**-m/--max-time <seconds>	        设置最大传输时间** 
*      --max-redirs <num>	        设置最大读取的目录数 
*      --max-filesize <bytes>	    设置最大下载的文件总量 
* -M/--manual	                    显示全手动 
* -n/--netrc	                    从netrc文件中读取用户名和密码 
*      --netrc-optional	            使用 .netrc 或者 URL来覆盖-n 
*      --ntlm	                    使用 HTTP NTLM 身份验证 
* -N/--no-buffer	                禁用缓冲输出 
* -o/--output	                    把输出写到该文件中 
* -O/--remote-name	                把输出写到该文件中，保留远程文件的文件名 
* -p/--proxytunnel	                使用HTTP代理 
*      --proxy-anyauth	            选择任一代理身份验证方法 
*      --proxy-basic	            在代理上使用基本身份验证 
*      --proxy-digest	            在代理上使用数字身份验证 
*      --proxy-ntlm	                在代理上使用ntlm身份验证 
* -P/--ftp-port <address>	        使用端口地址，而不是使用PASV 
* -q	                            作为第一个参数，关闭 .curlrc 
* -Q/--quote <cmd>	                文件传输前，发送命令到服务器 
* -r/--range <range>	            检索来自HTTP/1.1或FTP服务器字节范围 
* --range-file	                    读取（SSL）的随机文件 
* -R/--remote-time	                在本地生成文件时，保留远程文件时间 
*      --retry <num>	            传输出现问题时，重试的次数 
*      --retry-delay          	    传输出现问题时，设置重试间隔时间 
*      --retry-max-time             传输出现问题时，设置最大重试时间
*                                                              
**-s/--silent	                    静默模式。不输出任何东西** 
* -S/--show-error	                显示错误 
*      --socks4 <host[:port]>	    用socks4代理给定主机和端口 
*      --socks5 <host[:port]>	    用socks5代理给定主机和端口 
*      --stderr <file>	            
* -t/--telnet-option <OPT=val>	    Telnet选项设置 
*      --trace <file>	            对指定文件进行debug 
*      --trace-ascii <file>	Like    跟踪但没有hex输出 
*      --trace-time	                跟踪/详细输出时，添加时间戳 
* -T/--upload-file <file>	        上传文件 
*      --url <URL>	                Spet URL to work with 
* -u/--user <user[:password]>	    设置服务器的用户和密码 
* -U/--proxy-user <user[:password]> 设置代理用户名和密码 
* -w/--write-out [format]	        什么输出完成后 
*                              
**-x/--proxy <host[:port]>	        在给定的端口上使用HTTP代理** 
* -X/--request <command>	        指定什么命令 
* -y/--speed-time	                放弃限速所要的时间，默认为30 
* -Y/--speed-limit	                停止传输速度的限制，速度时间 

## 常用举例
### GET请求(-G/--get/省略)
```
curl http://www.xxxx.com/show?userId=111
```

### POST请求
以application/x-www-url-encoded 方式发送数据(-d/--data)：
```
curl -d "username=sunnyxd&password=12345" URL
```
以multipart/form-data 的方式发送数据(上传文件，-F/--form)：
```
curl -F filename=@/home/sunnyxd/file.tar.gz -F username=sunnyxd URL
```

### 设置cookie
使用cookie (-b/--cookie)
```
curl URL -b "username=sunnyxd;password=12345"
```
保存cookie (-c/--cookie-jar)
```
curl -d "username=sunnyxd&password=12345" -c ./cookie.txt URL 操作结束后把cookie写入文件cookie.txt
```
### 抓取页面(下载)
抓取页面保存到test.html：
```
curl -o test.html URL
或者curl URL > test.html
```
* -O 下载特定文件，url需要指定到一个具体的文件
* -C - 断点续传，- 自动推断出正确的续传位置，或者直接指定相应的字节偏移
* -f 显示抓取错误信息
* -x ip:port 使用代理
* -s 不显示进度信息
* -e/--referer 伪造来源地址
* --limit-rate 50k 限制下载速度
* --max-filesize bytes 指定可下载的最大文件大小
格式化显示响应信息
* -w 一次完整且成功的操作后输出指定格式的内容到标准输出。

### 查看接口响应时间
```
curl -o /dev/null -s -w "%{time_connect}:%{time_starttransfer}:%{time_total}\n" URL

第一个字段，是从命令启动到链接上用的时间
第二个字段，是开始传输数据所用的时间
第三个字段，是完成传输所用的时间
```

### 查看页面是否可用
```
curl -o /dev/null -s -w %{http_code} URL
```
监控接口可用性的一个简单demo：
```
#!/bin/bash
echo "check result:"
cat monitor_url | while read line
do
status_code=`curl -o /dev/null -s -w %{http_code} $line`
if [ $status_code -eq 200 ]
then
echo ${line}"is ok"
else
echo ${line}"is fail"
fi
done
curl -w详细介绍：http://www.letuknowit.com/post/17.html
```

### 设置浏览器代理 (-A/--user-agent)
```
curl URL -A "Mozilla/5.0
```

### 只打印响应头部信息
通过-I或者--head可以只打印出HTTP头部信息：
```
curl -I URL
```
### 用户认证(-u/--user)
用于HTTP或者FTP的认证，可以指定密码，也可以不指定密码在后续操作中输入密码：
```
curl -u user:pwd URL
curl -u user URL
```

### 通用头部信息传递(-H/--header)
```
curl -H "Host:127.0.0.1" -H "accept-language:zh-cn" URL
```

### 自动跳转到新网址
有的网址是自动跳转的。使用-L参数，curl就会跳转到新的网址。
```
curl -L URL
```

### 设置请求超时时间
```
curl --connect-timeout seconds URL
```
 
### 设置最大传输时间(-m/--max-time)
```
curl -m seconds URL
```

### 指定host请求
```
curl -H "Host:URL" http://192.168.1.1
```

### 代理请求
```
curl -x 192.168.1.1 URL
```

## 参考
> * [http://man.linuxde.net/curl](http://man.linuxde.net/curl)
> * [https://segmentfault.com/a/1190000005177475](https://segmentfault.com/a/1190000005177475)