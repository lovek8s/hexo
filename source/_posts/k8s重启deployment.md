---
layout: post
title: K8S重启Deployment的方式
author: owelinux
categories: 云原生
tags: k8s
excerpt: K8S重启Deployment的方式
mathjax: true
abbrlink: 5cd23594
date: 2019-12-27 11:21:54
---

# K8S重启Deployment的方式

有时候我们会需要重启Deployment，原因可能是：

docker image使用的是latest tag，这个latest在docker image registry已经更新了，我们需要重启deployment来使用新的latest
Pod运行缓慢但是还活着，我们就是想重启一下
ConfigMap/Secret变更了，想重启一下应用新配置
上面两种情况的共同之处在于，Deployment spec没有发生任何变化，因此即使你kubectl appply -f deployment-spec.yaml也是没用的，因为K8S会认为你这个没有变化就什么都不做了。

但是我们又不想使用手工删除Pod-让K8S新建Pod的方式来重启Deployment，最好的办法应该是像Updating a deployment一样，让K8S自己滚动的删除-新建Pod。

下面介绍四种方式重启：

    kubectl apply -f app.yaml
    kubectl delete -f app.yaml| kubectl create -f app.yaml
    kubectl get pod PODNAME  -o yaml | kubectl replace --force -f -
    kubectl set image deployment/nginx-deployment nginx=nginx:1.9.1
    kubectl -n beta patch deployment modeling-platform --patch '{"spec": {"template": {"spec": {"containers": [{"name": "modeling-platform","image": "nginx:'${build_tag}'","env": [{"name":"LAST_MANUAL_RESTART","value":"'${BUILD_ID}'"}]}]}}}}'


## 参考文档

* [https://k8smeetup.github.io/docs/tasks/run-application/update-api-object-kubectl-patch/](https://k8smeetup.github.io/docs/tasks/run-application/update-api-object-kubectl-patch/)

* [https://chanjarster.github.io/post/k8s-restart-deployment/](https://chanjarster.github.io/post/k8s-restart-deployment/)