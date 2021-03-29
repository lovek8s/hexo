---
layout: post
title: JIRA 7.13.0 实践笔记
author: owelinux
categories: linux
tags: linux
excerpt: JIRA 7.13.0 实践笔记
mathjax: true
abbrlink: 5f63d71c
date: 2018-12-05 10:23:54
---

* content
{:toc}

# JIRA 7.13.0 实践笔记 

jira有以下几种安装方式：

* Docker容器部署

* K8s helm部署

* k8s 部署

* 直接安装 

其中helm安装：[helm安装](https://itnext.io/jira-on-kubernetes-by-helm-8a38357da4e),下面详细介绍容器部署。

## 镜像构建配置

### Jira容器构建准备

破解文件下载：[jira7.2_hack.zip](https://github.com/idoall/docker/blob/master/ubuntu16.04-jira/7.2.7/files/usr/src/_jira/jira7.2_hack.zip)

```
git clone https://github.com/cptactionhank/docker-atlassian-jira-software

cd docker-atlassian-jira-software

cp atlassian-extras-3.2.jar atlassian-universal-plugin-manager-plugin-2.22.9.jar ./ 
```

### 定义 setenv.sh

修改默认使用jvm内存(将内存参数以变量传递给容器外部调用)：
vim setenv.sh
```
#
# One way to set the JIRA HOME path is here via this variable.  Simply uncomment it and set a valid path like /jira/home.  You can of course set it outside in the command terminal.  That will also work.
#
#JIRA_HOME=""

#
#  Occasionally Atlassian Support may recommend that you set some specific JVM arguments.  You can use this variable below to do that.
#
JVM_SUPPORT_RECOMMENDED_ARGS=""

#
# The following 2 settings control the minimum and maximum given to the JIRA Java virtual machine.  In larger JIRA instances, the maximum amount will need to be increased.
#
JVM_MINIMUM_MEMORY=${JVM_XMS:-384m}
JVM_MAXIMUM_MEMORY=${JVM_XMX:-768m}

#
# The following setting configures the size of JVM code cache.  A high value of reserved size allows Jira to work with more installed apps.
#
JVM_CODE_CACHE_ARGS='-XX:InitialCodeCacheSize=32m -XX:ReservedCodeCacheSize=512m'

#
# The following are the required arguments for JIRA.
#
JVM_REQUIRED_ARGS='-Djava.awt.headless=true -Datlassian.standalone=JIRA -Dorg.apache.jasper.runtime.BodyContentImpl.LIMIT_BUFFER=true -Dmail.mime.decodeparameters=true -Dorg.dom4j.factory=com.atlassian.core.xml.InterningDocumentFactory'

# Uncomment this setting if you want to import data without notifications
#
#DISABLE_NOTIFICATIONS=" -Datlassian.mail.senddisabled=true -Datlassian.mail.fetchdisabled=true -Datlassian.mail.popdisabled=true"


#-----------------------------------------------------------------------------------
#
# In general don't make changes below here
#
#-----------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------
# Prevents the JVM from suppressing stack traces if a given type of exception
# occurs frequently, which could make it harder for support to diagnose a problem.
#-----------------------------------------------------------------------------------
JVM_EXTRA_ARGS="-XX:-OmitStackTraceInFastThrow"

PRGDIR=`dirname "$0"`
cat "${PRGDIR}"/jirabanner.txt

JIRA_HOME_MINUSD=""
if [ "$JIRA_HOME" != "" ]; then
    echo $JIRA_HOME | grep -q " "
    if [ $? -eq 0 ]; then
            echo ""
            echo "--------------------------------------------------------------------------------------------------------------------"
                echo "   WARNING : You cannot have a JIRA_HOME environment variable set with spaces in it.  This variable is being ignored"
            echo "--------------------------------------------------------------------------------------------------------------------"
    else
                JIRA_HOME_MINUSD=-Djira.home=$JIRA_HOME
    fi
fi

JAVA_OPTS="-Xms${JVM_MINIMUM_MEMORY} -Xmx${JVM_MAXIMUM_MEMORY} ${JVM_CODE_CACHE_ARGS} ${JAVA_OPTS} ${JVM_REQUIRED_ARGS} ${DISABLE_NOTIFICATIONS} ${JVM_SUPPORT_RECOMMENDED_ARGS} ${JVM_EXTRA_ARGS} ${JIRA_HOME_MINUSD} ${START_JIRA_JAVA_OPTS}"

export JAVA_OPTS

# DO NOT remove the following line
# !INSTALLER SET JAVA_HOME

echo ""
echo "If you encounter issues starting or stopping JIRA, please see the Troubleshooting guide at http://confluence.atlassian.com/display/JIRA/Installation+Troubleshooting+Guide"
echo ""
if [ "$JIRA_HOME_MINUSD" != "" ]; then
    echo "Using JIRA_HOME:       $JIRA_HOME"
fi

# set the location of the pid file
if [ -z "$CATALINA_PID" ] ; then
    if [ -n "$CATALINA_BASE" ] ; then
        CATALINA_PID="$CATALINA_BASE"/work/catalina.pid
    elif [ -n "$CATALINA_HOME" ] ; then
        CATALINA_PID="$CATALINA_HOME"/work/catalina.pid
    fi
fi
export CATALINA_PID

if [ -z "$CATALINA_BASE" ]; then
  if [ -z "$CATALINA_HOME" ]; then
    LOGBASE=$PRGDIR
    LOGTAIL=..
  else
    LOGBASE=$CATALINA_HOME
    LOGTAIL=.
  fi
else
  LOGBASE=$CATALINA_BASE
  LOGTAIL=.
fi

PUSHED_DIR=`pwd`
cd $LOGBASE
cd $LOGTAIL
LOGBASEABS=`pwd`
cd $PUSHED_DIR

echo ""
echo "Server startup logs are located in $LOGBASEABS/logs/catalina.out"

# Set the JVM arguments used to start JIRA. For a description of the options, see
# http://www.oracle.com/technetwork/java/javase/tech/vmoptions-jsp-140102.html

#-----------------------------------------------------------------------------------
# This allows us to actually debug GC related issues by correlating timestamps
# with other parts of the application logs.
#-----------------------------------------------------------------------------------
GC_JVM_PARAMETERS=""
GC_JVM_PARAMETERS="-XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+PrintGCCause ${GC_JVM_PARAMETERS}"
GC_JVM_PARAMETERS="-Xloggc:$LOGBASEABS/logs/atlassian-jira-gc-%t.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=20M ${GC_JVM_PARAMETERS}"

CATALINA_OPTS="${GC_JVM_PARAMETERS} ${CATALINA_OPTS}"
export CATALINA_OPTS
```

### 定义Dockerfile

```
FROM openjdk:8-alpine

# Configuration variables.
ENV JIRA_HOME     /var/atlassian/jira
ENV JIRA_INSTALL  /opt/atlassian/jira
ENV JIRA_VERSION  7.13.0

# Install Atlassian JIRA and helper tools and setup initial home
# directory structure.
RUN set -x \
    && apk add --no-cache curl xmlstarlet bash ttf-dejavu libc6-compat \
    && mkdir -p                "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_HOME}/caches/indexes" \
    && chmod -R 700            "${JIRA_HOME}" \
    && mkdir -p                "${JIRA_INSTALL}/conf/Catalina" \
    && curl -Ls                "https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-7.13.0.tar.gz" | tar -xz --directory "${JIRA_INSTALL}" --strip-components=1 --no-same-owner \
    && curl -Ls                "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz" | tar -xz --directory "${JIRA_INSTALL}/lib" --strip-components=1 --no-same-owner "mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar" \
    && rm -f                   "${JIRA_INSTALL}/lib/postgresql-9.1-903.jdbc4-atlassian-hosted.jar" \
    && curl -Ls                "https://jdbc.postgresql.org/download/postgresql-42.2.1.jar" -o "${JIRA_INSTALL}/lib/postgresql-42.2.1.jar" \
    && chmod -R 700            "${JIRA_INSTALL}/conf" \
    && chmod -R 700            "${JIRA_INSTALL}/logs" \
    && chmod -R 700            "${JIRA_INSTALL}/temp" \
    && chmod -R 700            "${JIRA_INSTALL}/work" \
    && sed --in-place          "s/java version/openjdk version/g" "${JIRA_INSTALL}/bin/check-java.sh" \
    && echo -e                 "\njira.home=$JIRA_HOME" >> "${JIRA_INSTALL}/atlassian-jira/WEB-INF/classes/jira-application.properties" \
    && touch -d "@0"           "${JIRA_INSTALL}/conf/server.xml"

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
#USER daemon:daemon

# Expose default HTTP connector port.
EXPOSE 8080

# Set volume mount points for installation and home directory. Changes to the
# home directory needs to be persisted as well as parts of the installation
# directory due to eg. logs.
VOLUME ["/var/atlassian/jira", "/opt/atlassian/jira/logs"]

# Set the default working directory as the installation directory.
WORKDIR /var/atlassian/jira

COPY "docker-entrypoint.sh" "/"
COPY atlassian-extras-3.2.jar ${JIRA_INSTALL}/atlassian-jira/WEB-INF/lib/atlassian-extras-3.2.jar 
COPY atlassian-universal-plugin-manager-plugin-2.22.9.jar ${JIRA_INSTALL}/atlassian-jira/WEB-INF/atlassian-bundled-plugins/atlassian-universal-plugin-manager-plugin-2.22.9.jar
COPY setenv.sh ${JIRA_INSTALL}/bin/setenv.sh
COPY server.xml ${JIRA_INSTALL}/conf/server.xml

ENTRYPOINT ["/docker-entrypoint.sh"]

# Run Atlassian JIRA as a foreground process by default.
CMD ["/opt/atlassian/jira/bin/start-jira.sh", "-fg"]
```

### 定义 server.xml
自定义server.xml文件，需求后续可以配置https访问
```
<?xml version="1.0" encoding="utf-8"?>
<Server port="8005" shutdown="SHUTDOWN">
    <Listener className="org.apache.catalina.startup.VersionLoggerListener"/>
    <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on"/>
    <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener"/>
    <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener"/>
    <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener"/>

    <Service name="Catalina">
        <Connector port="8080" relaxedPathChars="[]|" relaxedQueryChars="[]|{}^&#x5c;&#x60;&quot;&lt;&gt;"
                   maxThreads="150" minSpareThreads="25" connectionTimeout="20000" enableLookups="false"
                   maxHttpHeaderSize="8192" protocol="HTTP/1.1" useBodyEncodingForURI="true" redirectPort="8443"
                   acceptCount="100" disableUploadTimeout="true" bindOnInit="false"/>

        <Engine name="Catalina" defaultHost="localhost">
            <Host name="localhost" appBase="webapps" unpackWARs="true" autoDeploy="true">

                <Context path="" docBase="${catalina.home}/atlassian-jira" reloadable="false" useHttpOnly="true">
                    <Resource name="UserTransaction" auth="Container" type="javax.transaction.UserTransaction"
                              factory="org.objectweb.jotm.UserTransactionFactory" jotm.timeout="60"/>
                    <Manager pathname=""/>
                    <JarScanner scanManifest="false"/>
                </Context>

            </Host>
            <Valve className="org.apache.catalina.valves.AccessLogValve"
                   pattern="%a %{jira.request.id}r %{jira.request.username}r %t &quot;%m %U%q %H&quot; %s %b %D &quot;%{Referer}i&quot; &quot;%{User-Agent}i&quot; &quot;%{jira.request.assession.id}r&quot;"/>
        </Engine>
    </Service>
</Server>
```
### 构建镜像
```
docker build -t jira:7.13.0 .
```

## Mysql本地安装

### yum 部署mysql

```
curl -LO http://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
yum localinstall mysql57-community-release-el7-11.noarch.rpm
yum install mysql-community-server
systemctl enable mysqld
systemctl start mysqld
systemctl status mysqld
# 查看密码
grep 'temporary password' /var/log/mysqld.log
# 登录 MySQL 并修改密码

mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass4!';
```

### 配置mysql数据库：
```
创建数据库：

mysql> CREATE DATABASE jira  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;

授连接次数据库的权限：

mysql>  grant all privileges on jira.* to jira@'.%' identified by 'jira';
mysql> flush privileges;
```

注意： jira7.13.0版本不支持utf8_general_ci的校验规则，因此创建数据库时必须指明utf8_bin校验规则！！


## 部署镜像

### Docker 本地部署
```
docker run --publish 8080:8080 --name jira -d local-jira:7.3.8
```

### 使用docker-compose方式

构建docker-compose.yml
```
jira:
  image: jira:7.13.0
  restart: always
  environment:
    - JVM_XMX=2048m
    - JVM_XMS=1024m
  ports:
    - '8080:8080'
  links:
    - db
  volumes:
    - ./data/jira:/var/atlassian/jira
    - ./data/logs:/opt/atlassian/jira/logs

db:
  image: mysql:5.7
  restart: always
  environment:
    - MYSQL_USER=jira
    - MYSQL_PASSWORD=jira
    - MYSQL_DATABASE=jira
    - MYSQL_ROOT_PASSWORD=jira
  volumes:
    - ./data/mysql:/var/lib/mysql

```

### 采用k8s集群方式运行

此环境在阿里云K8s容器平台部署

#### 创建pv
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hangzhou-b-ssd  
parameters:
  cachingmode: None
  kind: Managed
  storageaccounttype: Standard_LRS
provisioner: kubernetes.io/azure-disk
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
```

#### 创建pvc
```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: jira-data
spec:
  accessModes:
   - "ReadWriteOnce"
  resources:
    requests:
       storage: "100Gi"  
  storageClassName: "hangzhou-b-ssd"
```
#### 创建service
```
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.beta.kubernetes.io/alicloud-loadbalancer-cert-id: "cert-id"
    service.beta.kubernetes.io/alicloud-loadbalancer-protocol-port: "https:443,http:80"
  name: jira-svc
  namespace: default
spec:
  ports:
  - port: 443
    protocol: TCP
    targetPort: 8080
  selector:
    app: jira-svc
  sessionAffinity: None
  type: LoadBalancer       
```
这里采用阿里自带负载均衡方式部署，然后域名解析到负载均衡外网ip

#### 创建Deployment
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jira-deployment
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jira-svc
  template:
    metadata:
      labels:
        app: jira-svc
    spec:
      containers:
        - name: jira-svc
          image: jira:7.13.0
          imagePullPolicy: Always
          env:
          - name: JVM_XMX
            value: "2048m"
          - name: JVM_XMS
            value: "1024m"
          ports:
            - containerPort: 8080
          volumeMounts:
          - mountPath: "/var/atlassian/jira"
            name: jira-data         
      volumes:
      - name: jira-data
        persistentVolumeClaim:
          claimName: jira-data  
```
#### 部署
```
kubectl apply -f .
```


## 破解

首先按照安装步骤一步一步进行，到证书授权的时候，点击申请证书，然后得到许可证，填入即可，最后在应用程序--版本和许可证，可看到技术服务器截止日期 08/二月/33，即破解成功！(插件破解：免费试用--获取申请码---填入申请码---破解成功)

## 注意的问题

注意：jira插件管理中，atlassian-universal-plugin-manager-plugin插件绝对不要更新，否则插件破解会失效。

补充说明：

1、插件破解原理：

atlassian-universal-plugin-manager-plugin插件是进行插件管理的，只需要破解了这个插件，剩下的所有插件都自动破解完成了

2、如果破解不成功、插件管理版本高于2.22.4、或者不小心更新了atlassian-universal-plugin-manager-plugin这个插件怎么办？

遇到这种情况，需要到jira的安装目录和数据目录下，替换掉atlassian-universal-plugin-manager-plugin相关的所有文件。

具体操作步骤：

（1）到jira安装目录和数据目录下find出所有相关文件：
（2）替换、删除相关文件，保险起见，可在删除前对数据进行备份。 
（3）重启jira
（4）到插件管理中心查看插件授权期限，变为2099年

如何修改内存？

vim /opt/atlassian/jira/bin/setenv.sh
```
JVM_MINIMUM_MEMORY=${JVM_XMS:-384m}
JVM_MAXIMUM_MEMORY=${JVM_XMX:-768m}
```

如何解决mysql ssl报错?

vim /var/atlassian/jira/dbconfig.xml
```
<url>jdbc:mysql://address=(protocol=tcp)(host=mysql_hostname)(port=mysql_port)/jira?useUnicode=true&amp;characterEncoding=UTF8&amp;sessionVariables=default_storage_engine=InnoDB&amp;useSSL=false</url>
```
## 参考文档：
* [https://www.jianshu.com/p/744c23f93dfc](https://www.jianshu.com/p/744c23f93dfc)

* [https://cloud.tencent.com/developer/article/1027457](https://cloud.tencent.com/developer/article/1027457)

* [https://paper.tuisec.win/detail/29d80901a36cf52](https://paper.tuisec.win/detail/29d80901a36cf52)