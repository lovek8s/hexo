---
layout: post
title: Let's Encrypt通配符HTTPS证书申请
author: owelinux
categories: linux
tags: https
excerpt: Let's Encrypt通配符HTTPS证书申请
mathjax: true
abbrlink: aebc49f0
date: 2018-09-06 10:44:54
---

* content
{:toc}

# Let's Encrypt通配符HTTPS证书申请

Let's Encrypt 发布的 ACME v2 现已正式支持通配符证书，下面介绍三种方法申请证书。

## 使用acme.sh方式
acme.sh 实现了 acme 协议, 可以从 letsencrypt 生成免费的证书.

主要步骤:

* 安装 acme.sh
* 生成证书
* copy 证书到 nginx/apache 或者其他服务
* 更新证书
* 更新 acme.sh
* 出错怎么办, 如何调试

下面详细介绍.

### 1. 安装 acme.sh
```
curl  https://get.acme.sh | sh
```

* 1）安装目录中: ~/.acme.sh/
* 2) 自动为你创建 cronjob, 每天 0:00 点自动检测所有的证书, 如果快过期了, 需要更新, 则会自动更新证书.

### 2. 生成证书

acme.sh 实现了 acme 协议支持的所有验证协议. 一般有两种方式验证: http 和 dns 验证.

#### 1. http 方式

方式需要在你的网站根目录下放置一个文件, 来验证你的域名所有权,完成验证. 然后就可以生成证书了.
```
acme.sh  --issue  -d mydomain.com -d www.mydomain.com  --webroot  /home/wwwroot/mydomain.com/
``` 


#### 2. dns 方式

在域名上添加一条 txt 解析记录, 验证域名所有权.

这种方式的好处是, 你不需要任何服务器, 不需要任何公网 ip, 只需要 dns 的解析记录即可完成验证. 坏处是，如果不同时配置 Automatic DNS API，使用这种方式 acme.sh 将无法自动更新证书，每次都需要手动再次重新解析验证域名所有权。

其他api：[https://github.com/Neilpang/acme.sh/blob/master/dnsapi/README.md](https://github.com/Neilpang/acme.sh/blob/master/dnsapi/README.md)
##### 手动添加txt记录
1.生成txt记录
```
acme.sh  --issue  --dns   -d mydomain.com
```

2.域名管理面板中添加这条 txt 记录即可.

3.等待验证解析完成之后, 重新生成证书:
```
acme.sh  --renew   -d mydomain.com
```

##### 通过api自动添加txt记录

以 dnspod 为例, 登录到 dnspod 账号, 生成 api id 和 api key, 然后:
```
export DP_Id="1234"

export DP_Key="sADDsdasdgdsf"

acme.sh   --issue   --dns dns_dp   -d aa.com  -d www.aa.com
```

### 3. copy/安装 证书

正确的使用方法是使用 --installcert 命令,并指定目标位置, 然后证书文件会被copy到相应的位置, 例如:

```
acme.sh  --installcert  -d  <domain>.com   \
        --key-file   /etc/nginx/ssl/<domain>.key \
        --fullchain-file /etc/nginx/ssl/fullchain.cer \
        --reloadcmd  "service nginx force-reload"
```

Nginx 的配置 ssl_certificate 使用 /etc/nginx/ssl/fullchain.cer ，而非 /etc/nginx/ssl/<domain>.cer ，否则 SSL Labs 的测试会报 Chain issues Incomplete 错误。

nginx 配置
```
server {
    server_name www.fuckbb.tk;
    listen 443 http2 ssl;
    root /var/www/html;

    ssl on;
    ssl_certificate /etc/nginx/ssl/fullchain.cer;
    ssl_certificate_key /etc/nginx/ssl/fuckbb.tk.key;
    ssl_session_timeout 5m;
    ssl_protocols  SSLv2 SSLv3 TLSv1;
    ssl_ciphers  HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;  
}
```

### 4. 更新证书

目前证书在 60 天以后会自动更新, 你无需任何操作. 今后有可能会缩短这个时间, 不过都是自动的, 你不用关心.

### 5. 更新 acme.sh

升级 acme.sh 到最新版 :
```
acme.sh --upgrade
```
开启自动升级:
```
acme.sh  --upgrade  --auto-upgrade
```

关闭自动更新:
```
acme.sh --upgrade  --auto-upgrade  0
```

### 6. 出错怎么办：
如果出错, 请添加 debug log：
```
acme.sh  --issue  .....  --debug 
或者：
acme.sh  --issue  .....  --debug  2
```

## 采用docker方式
```
#revoke a cert
docker run --rm  -it  \
  -v "$(pwd)/out":/acme.sh  \
  --net=host \
  neilpang/acme.sh  --revoke -d example.com

#use dns mode
docker run --rm  -it  \
  -v "$(pwd)/out":/acme.sh  \
  neilpang/acme.sh  --issue --dns -d example.com

#use api-dns mode
docker run --rm  -it  \
  -v "$(pwd)/out":/acme.sh  \
  -e Ali_Key="xxxxxx" \
  -e Ali_Secret="xxxx" \
  neilpang/acme.sh  --issue --dns dns_dp -d domain.cn -d *.domain.cn

#run cron job
docker run --rm  -it  \
  -v "$(pwd)/out":/acme.sh  \
  --net=host \
  neilpang/acme.sh  --cron

#run cronjob
docker run --rm  -itd  \
  -v "$(pwd)/out":/acme.sh  \
  --net=host \
  --name=acme.sh \
  neilpang/acme.sh daemon

```

## certbot方式获取证书[不推荐]

### 1.获取certbot-auto
```
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto
```
### 2.开始申请证书
```
./certbot-auto --server https://acme-v02.api.letsencrypt.org/directory -d "*.xxx.com" -d "xxx.com" --manual --preerred-challenges dns-01 certonly
```
执行完这一步之后，会下载一些需要的依赖，稍等片刻之后，会提示输入邮箱，随便输入都行【该邮箱用于安全提醒以及续期提醒】,然后提示添加txt记录，带添加完成使用dig验证后回车，生成证书
/etc/letsencrypt/live/xxx.com/

### 3.续期
```
./certbot-auto renew
```

## nginx证书配置
```
server {
    server_name xxx.com;
    listen 443 http2 ssl;
    ssl on;
    ssl_certificate /etc/cert/xxx.cn/fullchain.pem;
    ssl_certificate_key /etc/cert/xxx.cn/privkey.pem;
    ssl_trusted_certificate  /etc/cert/xxx.cn/chain.pem;

    location / {
      proxy_pass http://127.0.0.1:6666;
    }
}
```

## 参考
*  [https://github.com/Neilpang/acme.sh/wiki/%E8%AF%B4%E6%98%8E](https://github.com/Neilpang/acme.sh/wiki/%E8%AF%B4%E6%98%8E)