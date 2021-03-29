---
title: linux系统调优指南(centos7.X)
top: false
cover: false
toc: true
mathjax: true
tags:
  - 系统调优
categories:
  - linux
abbrlink: b6b0fa45
date: 2018-07-18 15:14:54
password:
summary:
---

## 关闭不必要的服务(如打印服务等)
```
for owelinux in `chkconfig --list | grep "3:on" | awk '{print $1}'`; do chkconfig $owelinux off; done
for owelinux in crond network sshd rsyslog sysstat iptables; do chkconfig $owelinux on; done
```
## 关闭不需要的tty
```
\cp /etc/securetty  /etc/securetty.bak
>/etc/securetty
echo "tty1" >>/etc/securetty
echo "tty2" >>/etc/securetty
echo "tty3" >>/etc/securetty
```
## 调整linux 文件描述符大小
```
\cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%F)
ulimit -HSn 65535
echo -ne "
* soft nofile 65535
* hard nofile 65535
" >>/etc/security/limits.conf
echo "ulimit -c unlimited" >> /etc/profile
source /etc/profile
```
## 修改shell命令的history 记录个数和连接超时时间
```
echo "export HISTCONTROL=ignorespace" >>/etc/profile
echo "export HISTCONTROL=erasedups" >>/etc/profile
echo "HISTSIZE=500" >> /etc/profile

#修改帐户TMOUT值，设置自动注销时间
echo "export TMOUT=300" >>/etc/profile
echo "set autologout=300" >>/etc/csh.cshrc
source /etc/profile
```
## 清空系统版本信息加入登录警告
```
>/etc/motd
>/etc/issue
>/etc/redhat-release
echo "Authorized uses only. All activity may be monitored   and reported." >>/etc/motd
echo "Authorized uses only. All activity may be monitored   and reported." >> /etc/issue
echo "Authorized uses only. All activity may be monitored   and reported." >> /etc/issue.net
chown root:root /etc/motd /etc/issue  /etc/issue.net
chmod 644 /etc/motd /etc/issue  /etc/issue.net
```

## 优化内核TCP参数
```
cat >>/etc/sysctl.conf<<EOF
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
EOF
/sbin/sysctl -p
```

## 登录机器发邮件告警
```
yum -y install mailx
cat >>/root/.bashrc << EOF
echo 'ALERT - Root Shell Access (Server Name) on:' \`date\`\`who\`\`hostname\` | mail -s "Alert:Root Access from \`who | cut -d "(" -f2 | cut -d ")" #-f1\`" blue.yunwei@bluepay.asia
EOF
```

## 定时校正服务器时间
```
echo '0 * * * * /usr/sbin/ntpdate -u  0.cn.pool.ntp.org;/sbin/hwclock -w > /dev/null 2>&1' >> /var/spool/cron/root
/usr/sbin/ntpdate -u  0.cn.pool.ntp.org;/sbin/hwclock -w
systemctl  restart crond
```
## 停止ipv6
```
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
```
## 修改yum源
```
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum -y reinstall epel-release
yum clean all
yum makecache
```
## 关闭Selinux
```
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
```
## 安装必要的服务，更新系统软件
```
yum -y groupinstall "Development tools"
yum -y install ntpdate sysstat lrzsz wget nmap tree curl  epel-release lsof nano bash-completion net-tools lsof vim-enhanced
```
## ssh优化，加快连接速度
```
#1、配置空闲登出的超时间隔:
#2、禁用   .rhosts 文件
#3、禁用基于主机的认证
#4、禁止   root 帐号通过 SSH   登录
#5、用警告的   Banner
#6、iptables防火墙处理 SSH 端口22123
#7、修改 SSH   端口和限制 IP 绑定：
#8、禁用空密码：
#9、记录日志：

mv /etc/ssh/ /etc/sshbak
mkdir -p /application/tools
cd /application/tools
yum -y install wget C gcc cc
wget https://openbsd.hk/pub/OpenBSD/OpenSSH/portable/openssh-7.6p1.tar.gz
tar -zxf openssh-7.6p1.tar.gz
cd openssh-7.6p1
yum install -y zlib-devel openssl-devel pam pam-devel
./configure --prefix=/usr --sysconfdir=/etc/ssh --without-zlib-version-check  --with-pam
chmod 600 /etc/ssh/*_key
make -j4
rpm -e --nodeps `rpm -qa | grep openssh`
make install
ssh -V
cp contrib/redhat/sshd.init /etc/init.d/sshd
chkconfig --add sshd

mv /etc/ssh/sshd_config /etc/ssh/sshd_config_`date +%F`
cat >/etc/ssh/sshd_config<<EOF
Port 22123
PidFile /var/run/sshd.pid
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 30
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 15
#AllowUsers root lovelinux
PubkeyAuthentication yes
AuthorizedKeysFile  .ssh/authorized_keys
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication yes
GSSAPIAuthentication no
GSSAPICleanupCredentials yes
UsePAM no
ClientAliveInterval 0
ClientAliveCountMax 3
UseDNS no
Subsystem   sftp    /usr/lib/ssh/sftp-server
Ciphers aes128-ctr,aes192-ctr,aes256-ctr
Macs    hmac-sha2-256,hmac-sha2-512
EOF

echo "#save sshd messages also to sshd.log" >>/etc/rsyslog.conf
echo "local5.* /var/log/sshd.log" >>/etc/rsyslog.conf
systemctl restart rsyslog
systemctl stop sshd && systemctl start sshd
systemctl reload sshd
```
## 删除系统不需要的用户和用户组
```
   for i in adm lp sync shutdown halt news uucp operator games gopher
   do
      userdel $i  2>/dev/null
   done && action "delete user: " /bin/true || action "delete user: " /bin/false

   for i in adm  news uucp games dip pppusers popusers slipusers
   do
      groupdel $i  2>/dev/null
   done
```
## 修改密码认证的复杂度，和过期时间
```
mv /etc/pam.d/system-auth /etc/pam.d/system-auth_`date +%F`
cat >/etc/pam.d/system-auth<<EOF
#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the next time authconfig is run.
auth        required      pam_env.so
auth required pam_tally.so onerr=fail deny=6 unlock_time=1800
auth        sufficient    pam_unix.so nullok try_first_pass
auth        requisite     pam_succeed_if.so uid >= 500 quiet
auth        required      pam_deny.so
auth    sufficient    /lib/security/pam_unix.so likeauth nullok

account     required      pam_unix.so
account     sufficient    pam_localuser.so
account     sufficient    pam_succeed_if.so uid < 500 quiet
account     required      pam_permit.so

password    requisite     pam_cracklib.so try_first_pass retry=3  minlen=8 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.soetc/pam.d/system-auth
EOF
cat >/etc/pam.d/sshd<<EOF
#%PAM-1.0
#auth       required pam_google_authenticator.so nullok
auth       required     pam_sepermit.so
auth       substack     password-auth
auth       include      postlogin
# Used with polkit to reauthorize users in remote sessions
-auth      optional     pam_reauthorize.so prepare
account    required     pam_nologin.so
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      password-auth
session    include      postlogin
# Used with polkit to reauthorize users in remote sessions
-session   optional     pam_reauthorize.so prepare
EOF
```
## 使用noatime文件系统挂载选项
## 删除CentOS自带的sendmail，改用postfix
## 增加SWAP分区大小（一般是内存的2倍）
```
dd if=/dev/zero of=/mnt/swapfile bs=4M count=1024
mkswap /mnt/swapfile
swapon /mnt/swapfile
echo "/mnt/swapfile swap swap defaults 0 0" >>/etc/fstab
mount -a
free -m | grep -i swap
```
## 使用iptables关闭不需要对外开放的端口
```
systemctl disable firewalld
systemctl stop firewalld

yum -y install iptables-services
systemctl start iptables
systemctl start ip6tables
systemctl enable iptables
systemctl enable ip6tables

iptables -F
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 22123 -j ACCEPT
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -j DROP
service iptables save
```
## 启动系统审计服务
```
yum install audit*.* -y
cat >>/etc/audit/audit.rules<<EOF
-w /var/log/audit/ -k LOG_audit
-w /etc/audit/ -p wa -k CFG_audit
-w /etc/sysconfig/auditd -p wa -k CFG_auditd.conf
-w /etc/libaudit.conf -p wa -k CFG_libaudit.conf
-w /etc/audisp/ -p wa -k CFG_audisp
-w /etc/cups/ -p wa -k CFG_cups
-w /etc/init.d/cups -p wa -k CFG_initd_cups
-w /etc/netlabel.rules -p wa -k CFG_netlabel.rules
-w /etc/selinux/mls/ -p wa -k CFG_MAC_policy
-w /usr/share/selinux/mls/ -p wa -k CFG_MAC_policy
-w /etc/selinux/semanage.conf -p wa -k CFG_MAC_policy
-w /usr/sbin/stunnel -p x
-w /etc/security/rbac-self-test.conf -p wa -k CFG_RBAC_self_test
-w /etc/aide.conf -p wa -k CFG_aide.conf
-w /etc/cron.allow -p wa -k CFG_cron.allow
-w /etc/cron.deny -p wa -k CFG_cron.deny
-w /etc/cron.d/ -p wa -k CFG_cron.d
-w /etc/cron.daily/ -p wa -k CFG_cron.daily
-w /etc/cron.hourly/ -p wa -k CFG_cron.hourly
-w /etc/cron.monthly/ -p wa -k CFG_cron.monthly
-w /etc/cron.weekly/ -p wa -k CFG_cron.weekly
-w /etc/crontab -p wa -k CFG_crontab
-w /var/spool/cron/root -k CFG_crontab_root
-w /etc/group -p wa -k CFG_group
-w /etc/passwd -p wa -k CFG_passwd
-w /etc/gshadow -k CFG_gshadow
-w /etc/shadow -k CFG_shadow
-w /etc/security/opasswd -k CFG_opasswd
-w /etc/login.defs -p wa -k CFG_login.defs
-w /etc/securetty -p wa -k CFG_securetty
-w /var/log/faillog -p wa -k LOG_faillog
-w /var/log/lastlog -p wa -k LOG_lastlog
-w /var/log/tallylog -p wa -k LOG_tallylog
-w /etc/hosts -p wa -k CFG_hosts
-w /etc/sysconfig/network-scripts/ -p wa -k CFG_network
-w /etc/inittab -p wa -k CFG_inittab
-w /etc/rc.d/init.d/ -p wa -k CFG_initscripts
-w /etc/ld.so.conf -p wa -k CFG_ld.so.conf
-w /etc/localtime -p wa -k CFG_localtime
-w /etc/sysctl.conf -p wa -k CFG_sysctl.conf
-w /etc/modprobe.conf -p wa -k CFG_modprobe.conf
-w /etc/pam.d/ -p wa -k CFG_pam
-w /etc/security/limits.conf -p wa -k CFG_pam
-w /etc/security/pam_env.conf -p wa -k CFG_pam
-w /etc/security/namespace.conf -p wa -k CFG_pam
-w /etc/security/namespace.init -p wa -k CFG_pam
-w /etc/aliases -p wa -k CFG_aliases
-w /etc/postfix/ -p wa -k CFG_postfix
-w /etc/ssh/sshd_config -k CFG_sshd_config
-w /etc/vsftpd.ftpusers -k CFG_vsftpd.ftpusers
-a exit,always -F arch=b32 -S sethostname
-w /etc/issue -p wa -k CFG_issue
-w /etc/issue.net -p wa -k CFG_issue.net
EOF
systemctl enable auditd
service auditd  restart
```
## 部署完整性检查工具软件
```
yum -y install aide

#1）执行初始化，建立第一份样本库
aide -i
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

#2）更新到样本库
aide -u
cd /var/lib/aide/
mv aide.db.new.gz aide.db.gz

#3）定期执行入侵检测，并发送报告
# crontab -e
#45 17 * * * /usr/sbin/aide -C -V4 | /bin/mail -s ”AIDE REPORT $（date +%Y%m%d）” abcdefg#163.com
echo '45 23 * * * aide -C >> /var/log/aide/`date +%Y%m%d`_aide.log' >> /var/spool/cron/root

#记录aide可执行文件的md5 checksum：
md5sum /usr/sbin/aide
```
## 关闭ctrl+alt+del重启机器
```
rm -f /usr/lib/systemd/system/ctrl-alt-del.targe && init q
#恢复  ln -s /usr/lib/systemd/system/reboot.target /usr/lib/systemd/system/ctrl-alt-del.target
```
## 文件加锁及修改默认权限
```
#1、限制   at/cron给授权的用户:
rm -f /etc/cron.deny /etc/at.deny
echo root >/etc/cron.allow
echo root >/etc/at.allow
chown root:root /etc/cron.allow /etc/at.allow
chmod 400 /etc/cron.allow /etc/at.allow

#2、Crontab文件限制访问权限:
chown root:root /etc/crontab
chmod 400 /etc/crontab
chown -R root:root /var/spool/cron
chmod -R go-rwx /var/spool/cron
chown -R root:root /etc/cron.*
chmod -R go-rwx /etc/cron.*

#3、加锁重要口令文件和组文件
chattr +i /etc/passwd
chattr +i /etc/shadow
chattr +i /etc/group
chattr +i /etc/gshadow
chattr +i /etc/xinetd.conf
chattr +i /etc/services
```