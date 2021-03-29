---
title: 做运维需要注意什么？
top: false
cover: false
toc: true
mathjax: true
tags:
  - 学习方法
categories:
  - linux
abbrlink: 45d44ad3
date: 2018-07-17 10:14:54
password:
summary:
---

运维应该怎么分阶段学习？

- 机器名不要设置为localhost。
- 只读共享，不需要（ro，sync），只需（ro）即可。
- 要学会规范，按照要求部署，哪怕一个字符都不要错。
- 敲路径时候尽量复制粘贴。少自己敲字符。防止简单的字符错误。
- 记得开机自动挂载放到/etc/rc.loacl（带注释）。不要放在fstab里（NFS不能放，本地系统可以放）。
- 切换root方法，sudo su -
- 每隔步骤操作后都要及时检查，确保每一步正确，起码不犯超级菜的错误。
- NFS服务端共享目录可写时，不要给777权限，修改用户或属组nfsnobody。可读时权限属组都不需要动，就默认root即可。
- 增加SecureCRT标签时，不需要新建标签。直接复制标签然后去改（配置现成的）。
- 提前关闭iptables和防火墙，克隆虚拟机之前就优化好。
- 确保所有服务器uid为65534的用户为nfsnobody或者所有服务器都有具备uid为65534这样的用户。
- 模拟错误：模拟重现故障的能力是运维人员最重要的能力。