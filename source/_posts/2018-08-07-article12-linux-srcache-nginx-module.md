---
layout: post
title: srcache-nginx-module+pika实现nginx页面缓存
author: owelinux
categories: linux
tags: nginx pika cache
excerpt: srcache-nginx-module+pika实现nginx页面缓存.
mathjax: true
abbrlink: 7602f51b
date: 2018-08-07 15:41:54
---

* content
{:toc}

# srcache-nginx-module+pika实现nginx页面缓存

缓存应用场景：客户端（浏览器缓存）、数据库缓存、代理层缓存、应用层缓存等；

针对代理层缓存，我们可以将静态资源放入cdn或者本地页面缓存加快用户访问速度，缓解服务器压力。

下面我们针对页面缓存采用pika+srcache方案：

## openresty编译模块 
以下必要模块支持：
> * srcache-nginx-module
> * ngx_lua 
> * memc-nginx-module
> * redis2-nginx-module
> * redis-nginx-module

生产应用的编译参数：
```
[root@WEB3 ~]# /usr/local/openresty/nginx/sbin/nginx -V
nginx version: openresty/1.11.2.4
built by gcc 4.4.7 20120313 (Red Hat 4.4.7-4) (GCC) 
built with OpenSSL 1.0.1e-fips 11 Feb 2013
TLS SNI support enabled
configure arguments: --prefix=/usr/local/openresty/nginx --with-cc-opt=-O2 --add-module=../ngx_devel_kit-0.3.0 --add-module=../echo-nginx-module-0.60 --add-module=../xss-nginx-module-0.05 --add-module=../ngx_coolkit-0.2rc3 --add-module=../set-misc-nginx-module-0.31 --add-module=../form-input-nginx-module-0.12 --add-module=../encrypted-session-nginx-module-0.06 --add-module=../srcache-nginx-module-0.31 --add-module=../ngx_lua-0.10.8 --add-module=../ngx_lua_upstream-0.06 --add-module=../headers-more-nginx-module-0.32 --add-module=../array-var-nginx-module-0.05 --add-module=../memc-nginx-module-0.18 --add-module=../redis2-nginx-module-0.14 --add-module=../redis-nginx-module-0.3.7 --add-module=../rds-json-nginx-module-0.14 --add-module=../rds-csv-nginx-module-0.07 --with-ld-opt=-Wl,-rpath,/usr/local/openresty/luajit/lib --with-pcre=/usr/local/pcre-8.38 --with-stream --with-http_ssl_module
```

## pika介绍
### Pika是什么
Pika是DBA和基础架构组联合开发的类Redis 存储系统，所以完全支持Redis协议，用户不需要修改任何代码，就可以将服务迁移至Pika。Pika是一个可持久化的大容量Redis存储服务，兼容string、hash、list、zset、set的绝大接口兼容详情，解决Redis由于存储数据量巨大而导致内存不够用的容量瓶颈，并且可以像Redis一样，通过slaveof命令进行主从备份，支持全同步和部分同步。同时DBA团队还提供了迁移工具， 所以用户不会感知这个迁移的过程，迁移是平滑的。

### 与Redis的比较
Pika相对于Redis，最大的不同就是Pika是持久化存储，数据存在磁盘上，而Redis是内存存储，由此不同也给Pika带来了相对于Redis的优势和劣势

优势：

1.容量大：Pika没有Redis的内存限制, 最大使用空间等于磁盘空间的大小

2.加载db速度快：Pika在写入的时候, 数据是落盘的, 所以即使节点挂了, 不需要rdb或者oplog，Pika重启不用加载所有数据到内存就能恢复之前的数据, 不需要进行回放数据操作。

3.备份速度快：Pika备份的速度大致等同于cp的速度（拷贝数据文件后还有一个快照的恢复过程，会花费一些时间），这样在对于百G大库的备份是快捷的，更快的备份速度更好的解决了主从的全同步问题

劣势：
由于Pika是基于内存和文件来存放数据, 所以性能肯定比Redis低一些, 但是我们一般使用SSD盘来存放数据, 尽可能跟上Redis的性能。

### 适用场景
从以上的对比可以看出, 如果你的业务场景的数据比较大，Redis 很难支撑， 比如大于50G，或者你的数据很重要，不允许断电丢失，那么使用Pika 就可以解决你的问题。 而在实际使用中，Pika的性能大约是Redis的50%。

### Pika的特点
1.容量大，支持百G数据量的存储
2.兼容Redis，不用修改代码即可平滑从Redis迁移到Pika
3.支持主从(slaveof)
4.完善的运维命令

### 当前适用情况
目前Pika在线上部署并运行了20多个巨型（承载数据与Redis相比）集群 粗略的统计如下：当前每天承载的总请求量超过100亿，当前承载的数据总量约3TB

### 二进制包安装部署
```
cd /usr/local/
wget https://github.com/Qihoo360/pika/releases/download/v3.0.0/pika-linux-x86_64-v3.0.0.tar.bz2
tar -jxvf pika-linux-x86_64-v3.0.0.tar.bz2 
mv pika-linux-x86_64-v3.0.0  pika
# 增加开机自启动
echo "/usr/local/pika/output/bin/pika -c /usr/local/pika/output/conf/pika.conf" >> /etc/rc.local
# 启动
/usr/local/pika/output/bin/pika -c /usr/local/pika/output/conf/pika.conf
# 验证
[root@WEB3 output]# ss -lntp | grep 9221
LISTEN     0      128               127.0.0.1:9221                     *:*      users:(("pika",23138,50))
LISTEN     0      128             10.30.10.11:9221                     *:*      users:(("pika",23138,49))
```

## 配置nginx
cat nginx.conf
```
   lua_package_path "/usr/local/openresty/nginx/lua/?.lua;;";
   lua_shared_dict config 320m;
   lua_shared_dict srcache_locks 10m;
   lua_shared_dict mn_whiteurl 1m;

   init_by_lua_file /usr/local/openresty/nginx/lua/init.lua;
   access_by_lua_file /usr/local/openresty/nginx/lua/waf.lua;
   body_filter_by_lua_file /usr/local/openresty/nginx/lua/body_cache.lua;

   include /usr/local/openresty/nginx/conf.d/*.conf;

    server {
        listen       80;
        server_name  www.test.com;
        root /var/www/test;
        index  index.html index.htm index.php;

        access_log  /var/log/nginx/access.log main;
        error_log /var/log/nginx/error.log;

        userid on;
        userid_domain test.com;
        userid_expires 1095d;
		
	    upstream redis_m {
           server 127.0.0.1:9221;
           server 192.168.1.1:9221 backup;
           keepalive 4096;
        }
		
		upstream memcache_m {
           server 127.0.0.1:11214;
           server 192.168.1.1:11214 backup;
           keepalive 4096;
        }

        location /memc {
                internal;
                set $memc_cmd $arg_cmd;
                memc_cmds_allowed get set add delete flush_all;
                memc_connect_timeout 300ms;
                memc_send_timeout 300ms;
                memc_read_timeout 300ms;
                set_unescape_uri $memc_key $arg_key;
                set $memc_exptime $arg_expiretime;
                memc_pass memcache_m;
        }

        location = /redisttl {
            internal;
            set_unescape_uri $key $arg_key;
            set_md5 $key;
            redis2_query ttl $key;
            redis2_pass redis_m;
        }
        location = /redispersist {
            internal;
            set_unescape_uri $key $arg_key;
            set_md5 $key;
            redis2_query persist $key;
            redis2_pass redis_m;
        }

        location = /redis2clearcache {
                internal;
                set_unescape_uri $exptime $arg_expiretime;
                set_unescape_uri $key $arg_key;
                redis2_query expire $key $exptime;
                redis2_pass redis_m;
        }


        location = /redis {
                internal;
                set $redis_key $arg_key;
                redis_pass redis_m;
        }

        location = /redis2 {
                internal;
                set_unescape_uri $exptime $arg_expiretime;
                set_unescape_uri $key $arg_key;

                redis2_query set $key $echo_request_body;
                redis2_query expire $key $exptime;
                redis2_pass redis_m;
        }

        location = /lua_memc_del {
                set $cache_stale 0;  # 1 day
                content_by_lua '
                ngx.header.content_type = "text/plain";
                if ngx.var.arg_pwd ~= "to8to" then
                        ngx.say("error");
                else
                        local res = ngx.location.capture("/redis2clearcache", {
                                        args = { expiretime = ngx.var.cache_stale,key = ngx.var.arg_key}
                                        })
                        if res.status == 200 then
                                ngx.say(res.body);
                        else
                                ngx.say("not exist");
                        end
                end
                ';
        }

        location / {
        
                if (!-e $request_filename)
                {
                rewrite ^(.*)$ /index.php last;
                }
        }


        location ~* ^.+\.(ico|gif|jpg|jpeg|png|css|js|txt|swf|wav|bmp|webp|apk|zip|rar)$ {
                access_log off;
                expires 30d;
        }

        location ~* "\.htaccess$" {
            deny  all;
        }
        
        location ~* "/(\.svn|\.git|runtime|protected|framework)/" {
            deny all;
        }
        
        location ~* "^/(assets|html|css|js|images|img|static)/(.*)\.(php|php5)$"
        {
            deny all;
        }

        location ~ \.php$ {
                if (!-e $request_filename)
                {
                    rewrite ^(.*)$ /index.php last;
                }
                try_files /index.php =404;
                set $prefix_wap "wap";
                set_md5 $key $prefix_wap$host$request_uri;
                set $mtime 3600;
                set $skip 0;

                if ($request_uri ~* ^\/(\?(.*))?$)
                {
                        set $skip 1;
                        set $mtime 0;
                }


                if ($request_uri ~* /index/Citycookie )
                {
                        set $skip 1;
                        set $mtime 0;
                }



                if ($request_uri ~* ^/test(.*)$)
                {
                        set $skip 0;
                        set $mtime 604800;
                }

                #此if判断一定要放在最后,否则会出现POST请求被缓存的情况
                if ($request_method = POST)
                {
                         set $skip 1;
                         set $mtime 0;
                }

                srcache_fetch_skip $skip;
                srcache_store_skip $skip;
                set $cache_status 0;
                add_header  Cache-status $cache_status;

                set $cache_lock srcache_locks;
                set $cache_ttl /redisttl;
                set $cache_persist /redispersist;
                set $cache_key $prefix_wap$host$request_uri;
                set $cache_stale 86400;  # 1 day
 
                set_by_lua $expireTime 'return ngx.var.mtime + ngx.var.cache_stale';
                rewrite_by_lua_file /usr/local/openresty/lualib/resty/cache.lua;
 
                if ($http_x_skip_fetch != TRUE){
                        srcache_fetch GET /redis key=$key;
                }
                srcache_store PUT /redis2 key=$key&expiretime=$expireTime;

                srcache_methods GET PUT POST;
                add_header X-Cached-From $srcache_fetch_status;
                add_header Cache-Control max-age=$mtime;
                if ( $mtime = 0)
                {
                    add_header Cache-Control no-cache;
                }
                fastcgi_pass   127.0.0.1:9000;
                fastcgi_index  index.php;
                fastcgi_param  SCRIPT_FILENAME  $document_root/$fastcgi_script_name;
                include        fastcgi_params;
                fastcgi_intercept_errors on;
        }

    }
```

## 验证缓存情况
```
[root@WEB3 ~]# curl -I  -H 'host:www.test.com' http://127.0.0.1/test/
HTTP/1.1 200 OK
Server: openresty
Date: Tue, 07 Aug 2018 08:49:36 GMT
Content-Type: text/html;charset=utf-8
Content-Length: 90799
Connection: keep-alive
Vary: Accept-Encoding
Cache-status: 0
X-Cached-From: HIT
Cache-Control: max-age=604800
Set-Cookie: uid=fwAAAVtpXSC+sTyIAwMHAg==; expires=Fri, 06-Aug-21 08:49:36 GMT; domain=test.com; path=/
```
## 缓存命中率分析
```
 awk '{if($(NF-1) ~ "HIT") hit++} END {printf "file:'$a' time:'$LAST_DAY': %d %d %.2f%n" ,hit,NR,hit/NR}' /var/log/nginx/access.log
```
## 本文涉及的lua脚本
[cache.lua](https://raw.githubusercontent.com/owelinux/owelinux.github.io/master/images/2018-08-07-article12-linux-srcache-nginx-module/cache.lua)

# 参考：
> * [https://github.com/Qihoo360/pika/wiki](https://github.com/Qihoo360/pika/wiki)
> * [https://github.com/openresty/srcache-nginx-module](https://github.com/openresty/srcache-nginx-module)
