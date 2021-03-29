---
layout: post
title: kubernetes 之 Ingress 使用总结
author: owelinux
categories: 云原生
tags: k8s
excerpt: kubernetes 之 Ingress 使用总结
mathjax: true
abbrlink: 2f521ea8
date: 2018-12-27 11:21:54
---

* content
{:toc}

# kubernetes 之 Ingress 使用总结


## 前言
Kubernetes暴露服务的方式有多种，如LoadBalancer、NodePort、Ingress等。LoadBalancer一般用于云平台，平常一般用NodePort暴露服务，非常方便。但是由于NodePort需要指定宿主机端口，一旦服务多起来，多个端口就难以管理。那么，这种情况下，使用Ingress暴露服务更加合适。


## Ingress组成
Ingress由三部分组成：

* 反向代理负载均衡器

    比如Nginx、Haproxy、Apache、traefik等

* Ingress Controller

    通过与 Kubernetes API 交互，动态的去感知集群中 Ingress 规则变化，然后读取它，按照自定义的规则，规则就是写明了哪个域名对应哪个service，生成一段 Nginx 配置，再写到 Nginx-ingress-control的 Pod 里，这个 Ingress Contronler 的pod里面运行着一个nginx服务，控制器会把生成的nginx配置写入/etc/nginx.conf文件中，然后 reload 一下 使用配置生效。以此来达到域名分配置及动态更新的问题。


* Ingress

    kubernetes的一个资源对象，用于编写定义规则

如下是一个很简单的ingress.yml配置：
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: test-ingress
spec:
  rules:
  - http:
      paths:
      - path: /testpath
        backend:
           serviceName: test
           servicePort: 80
```

若需要添加新的转发规则，只需修改上述文件，然后执行kubectl apply -f ingress.yml即可，或者执行kubectl edit直接编辑后保存，通过kubectl logs可以看到ingress-controller的Nginx配置是否更新成功。Ingress可以和Ingress Controller不在同一namespace，但必须与声明的服务在同一namespace。同样，一个集群内也可以部署多个Ingress，一个Controller可以匹配多个Ingress。

## 部署

部署一些必要的服务:

```
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/namespace.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/default-backend.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/configmap.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/tcp-services-configmap.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/udp-services-configmap.yaml \
    | kubectl apply -f -
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/service-nodeport.yaml \
    | kubectl apply -f -
```
上面的default-backend.yml用于部署默认服务，当ingress找不到相应的请求时会返回默认服务，官方的默认服务返回404，也可以定制自己的默认服务。

基于RBAC部署Ingress Controller：
```
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/rbac.yaml \
    | kubectl apply -f -

curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/with-rbac.yaml \
    | kubectl apply -f -
```
也可以基于非RBAC模式部署：
```
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/without-rbac.yaml \
    | kubectl apply -f -
```
部署Ingress，假设集群内已经存在一个test服务，创建ingress.yml声明的规则如下：
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-nginx
spec:
  rules:
  - host: test.com
    http:
      paths:
      - backend:
           serviceName: test
           servicePort: 80
```
至此，ingress就部署完成了。配置hosts到Controller的PodIP，然后集群外访问test.com就可以访问test服务了。注意：因为官方的Ingress Controller默认并没有开启hostNetwork模式，所以这里hosts配置的是Controller的PodIP。但是考虑到Pod重新调度后其IP会更改，那么hosts配置也要同时更改，所以一般建议开启hostNetwork模式，使Controller监听宿主机的端口，这样配置hosts时只需要配置Pod所在的节点IP即可。有人会说，如果Pod重新调度到其他节点了，hosts配置不是也要改变吗？不错，这种情况下，我们可以通过nodeSelector指定Ingress Controller调度到某个节点。这样hosts配置就不用变了。修改如下：
```
...
nodeSelector:                   # 指定Ingress Controller调度到某个节点
  nodeName: myNodeName
hostNetwork: true               # 开启hostNetwork模式
containers:
  - name: nginx-ingress-controller
    image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.10.2
    args:
      - /nginx-ingress-controller
      - --default-backend-service=$(POD_NAMESPACE)/default-http-backend
      - --configmap=$(POD_NAMESPACE)/nginx-configuration
      - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
      - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
      - --annotations-prefix=nginx.ingress.kubernetes.io
···
```

## Ingress Controller匹配Ingress
当集群内创建多个Controller时，如何使某个Controller只监听对应的Ingress呢？这里就需要在Ingress中指定annotations，如下：
```
metadata:
  name: nginx-ingress
  namespace: ingress-nginx
  annotations:
    kubernetes.io/ingress.class: "nginx"                  # 指定ingress.class为nginx
```
然后在Controller中指定参数--ingress-class=nginx：
```
args:
  - /nginx-ingress-controller
  - --default-backend-service=$(POD_NAMESPACE)/default-http-backend
  - --configmap=$(POD_NAMESPACE)/nginx-configuration
  - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
  - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
  - --annotations-prefix=nginx.ingress.kubernetes.io
  - --ingress-class=nginx-prod                                 # 指定ingress-class值为nginx，与对应的Ingress匹配
```
最后需要在rbac中指定参数 - "ingress-controller-leader-nginx-prod" [参考](https://github.com/kubeapps/kubeapps/issues/120)
```
    resources:
      - configmaps
    resourceNames:
      # Defaults to "<election-id>-<ingress-class>"
      # Here: "<ingress-controller-leader>-<nginx>"
      # This has to be adapted if you change either parameter
      # when launching the nginx-ingress-controller.
      - "ingress-controller-leader-nginx-prod"
```


这样，该Controller就只监听带有kubernetes.io/ingress.class: "nginx"annotations的Ingress了。我们可以声明多个带有相同annotations的Ingress，它们都会被对应Controller监听。Controller中的nginx默认监听80和443端口，若要更改可以通过--http-port和--https-port参数来指定，更多参数可以在[这里](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/cli-arguments.md)找到。

在实际应用场景，常常会把多个服务部署在不同的namespace，来达到隔离服务的目的，比如A服务部署在namespace-A，B服务部署在namespace-B。这种情况下，就需要声明Ingress-A、Ingress-B两个Ingress分别用于暴露A服务和B服务，且Ingress-A必须处于namespace-A，Ingress-B必须处于namespace-B。否则Controller无法正确解析Ingress的规则。

## Ingress 开启 TLS / HTTPS


```
# 使用以下命令生成自签名证书和私钥
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CERT_FILE} -subj "/CN=${HOST}/O=${HOST}"`

# 通过以下方式在集群中创建密钥
kubectl create secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE}
```

创建完成后证书类型应该是 kubernetes.io/tls.

注：默认情况下，如果为该Ingress启用了TLS，则控制器会使用308永久重定向响应将HTTP客户端重定向到HTTPS端口443。

可以使用ssl-redirect: "false" 在NGINX config map文件声明，也可以使用nginx.ingress.kubernetes.io/ssl-redirect: "false" 特定资源中的注释per-Ingress 禁用此功能

创建一个支持https的域名：
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx-test
  name: mp-test
  namespace: default
spec:
  rules:
    - host: mp-test.test.com
      http:
        paths:
          - backend:
              serviceName: modeling-platform
              servicePort: 80
  tls:
    - hosts:
        - mp-test.test.com
      secretName: test.com
```

## 总结
* 集群内可以声明多个Ingress和多个Ingress Controller

* 一个Ingress Controller可以监听多个Ingress

* Ingress和其定义的服务必须处于同一namespace

## 参考文档

[http://bazingafeng.com/2018/02/10/deploy-ingress-in-kubernetes/](http://bazingafeng.com/2018/02/10/deploy-ingress-in-kubernetes/)

[https://www.cnblogs.com/xzkzzz/p/9577640.html](https://www.cnblogs.com/xzkzzz/p/9577640.html)

[https://confluence.atlassian.com/adminjiraserver071/connecting-to-an-ldap-directory-802592350.html](https://confluence.atlassian.com/adminjiraserver071/connecting-to-an-ldap-directory-802592350.html)