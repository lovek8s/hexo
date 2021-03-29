---
layout: post
title: k8s Sidecar 注入讲解及应用
author: owelinux
categories: 云原生
tags: k8s
excerpt: k8s Sidecar 注入讲解及应用
mathjax: true
abbrlink: e92d7d36
date: 2021-03-26 16:21:54
---

# k8s Sidecar 注入讲解及应用


## 背景

起初最开始是用jenkins作为构建工具，需求需要对接公司运维平台呈现实时构建日志。但遇到的痛点是本身jenkins home目录已经挂载了阿里云盘，如果在挂载取日志会对磁盘造成压力。于是有了以下方案。

1、jenkins容器增加一个nginx来暴露日志文件，平台去日志文件展示。

2、程序读取jenkins接口获取构建日志。

方案二直接paas，任务量多，频繁调用接口容器导致jenkins挂掉。而方案一需要另外编排jenkins容器，但发现可以通过Sidecar注入一个附加容器来截取日志。

## Sidecar

将应用程序的功能划分为单独的进程运行在同一个最小调度单元中（例如 Kubernetes 中的 Pod）可以被视为 **sidecar 模式**。就像连接了 Sidecar 的三轮摩托车一样，在软件架构中， Sidecar 连接到父应用并且为其添加扩展或者增强功能。Sidecar 应用与主应用程序松散耦合。它可以屏蔽不同编程语言的差异，统一实现微服务的可观察性、监控、日志记录、配置、断路器等功能。

### ![sidecar](https://docs.microsoft.com/en-us/azure/architecture/patterns/_images/sidecar.png)

### 使用 Sidecar 模式的优势

使用 sidecar 模式部署服务网格时，无需在节点上运行代理，但是集群中将运行多个相同的 sidecar 副本。在 sidecar 部署方式中，每个应用的容器旁都会部署一个伴生容器（如 [Envoy](https://www.servicemesher.com/istio-handbook/GLOSSARY.html#envoy) 或 [MOSN](https://www.servicemesher.com/istio-handbook/GLOSSARY.html#mosn)），这个容器称之为 sidecar 容器。Sidecar 接管进出应用容器的所有流量。在 Kubernetes 的 Pod 中，在原有的应用容器旁边注入一个 Sidecar 容器，两个容器共享存储、网络等资源，可以广义的将这个包含了 sidecar 容器的 Pod 理解为一台主机，两个容器共享主机资源。

因其独特的部署结构，使得 sidecar 模式具有以下优势：

- 将与应用业务逻辑无关的功能抽象到共同基础设施，降低了微服务代码的复杂度。
- 因为不再需要编写相同的第三方组件配置文件和代码，所以能够降低微服务架构中的代码重复度。
- Sidecar 可独立升级，降低应用程序代码和底层平台的耦合度。
- Sidecar可以访问与主应用程序相同的资源。例如，Sidecar可以监视Sidecar和主应用程序使用的系统资源。
- 由于它靠近主应用程序，因此它们之间的通信没有明显的延迟。
- 即使对于不提供扩展机制的应用程序，也可以使用sidecar来扩展功能，方法是将其作为自己的进程附加到与主应用程序相同的主机或子容器中。

### 问题与注意事项

- 考虑将用于部署服务，流程或容器的部署和打包格式。容器特别适合于Sidecar模式。
- 设计Sidecar服务时，请仔细确定进程间通信机制。除非性能要求不切实际，否则请尝试使用与语言或框架无关的技术。
- 在将功能放入Sidecar中之前，请考虑将其作为单独的服务或更传统的守护程序是否会更好地工作。
- 还需要考虑是否可以将功能实现为库或使用传统的扩展机制。特定语言的库可能具有更深层次的集成和更少的网络开销。

### 何时使用此模式

在以下情况下使用此模式：

- 您的主应用程序使用一组不同的语言和框架。位于Sidecar服务中的组件可由使用不同框架以不同语言编写的应用程序使用。
- 组件由远程团队或其他组织拥有。
- 组件或功能必须与应用程序位于同一主机上
- 您需要共享主应用程序整个生命周期但可以独立更新的服务。
- 您需要对特定资源或组件的资源限制进行细粒度的控制。例如，您可能想限制特定组件使用的内存量。您可以将组件部署为辅助工具，并独立于主应用程序管理内存使用情况。

此模式可能不适合：

- 需要优化进程间通信时。父应用程序和Sidecar服务之间的通信包括一些开销，特别是调用中的延迟。对于健谈界面，这可能不是可接受的折衷方案。
- 对于小型应用程序，为每个实例部署Sidecar服务的资源成本不值得使用隔离的优势。
- 当服务需要与主要应用程序进行不同的缩放或独立于主要应用程序进行缩放时。如果是这样，最好将该功能部署为单独的服务。

### 应用场景

Sidecar模式适用于许多情况。一些常见的例子：

- 基础结构API。基础结构开发团队创建与每个应用程序一起部署的服务，而不是特定语言的客户端库来访问基础结构。该服务作为sidecar加载，并为基础结构服务提供公共层，包括日志记录，环境数据，配置存储，发现，运行状况检查和看门狗服务。Sidecar还监视父应用程序的宿主环境和进程（或容器），并将信息记录到集中式服务中。
- 管理NGINX / HAProxy。使用可监视环境状态的sidecar服务部署NGINX，然后在需要状态更改时更新NGINX配置文件并回收该过程。
- Ambassador sidecar 。部署Ambassador服务作为辅助工具。该应用程序通过Ambassador进行调用，该大使处理请求记录，路由，断路以及其他与连接相关的功能。
- 前置代理。将NGINX代理放置在node.js服务实例的前面，以处理为该服务提供的静态文件内容。

### 最佳实践：

1、prometheus 集成 Thanos Sidecar

Thanos通过Sidecar与现有Prometheus服务器集成，该与Prometheus服务器运行在同一台机器上或同一Pod中。

Sidecar的目的是将Prometheus数据备份到“对象存储”存储桶中，并允许其他Thanos组件通过gRPC API访问Prometheus指标。

```bash
prometheus \
  --storage.tsdb.max-block-duration=2h \
  --storage.tsdb.min-block-duration=2h \
  --web.enable-lifecycle
thanos sidecar \
    --tsdb.path        "/path/to/prometheus/data/dir" \
    --prometheus.url   "http://localhost:9090" \
    --objstore.config-file  "bucket.yml"


示例内容bucket.yml：
type: GCS
config:
  bucket: example-bucket
```



2、jenkins 日志通过nginx暴露

```yaml
apiVersion: apps.kruise.io/v1alpha1
kind: SidecarSet
metadata:
  name: log-sidecar
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: jenkins  # 往所有带 long-term 标签的 Pod 中注入
  containers:
  - name: log-collector
    image: xxx/nginx:nginx-jenkinslog1.0
    ports:
       - name: nginx-log
         containerPort: 80
    volumeMounts:
    - name: jenkins-home
      mountPath: /var/jenkins_home
  volumes:
  - name: jenkins-home    # 定义一个名为 log-volume 的卷
    emptyDir: {}
```



3、日志采集上报

```yaml
apiVersion: apps.kruise.io/v1alpha1
kind: SidecarSet
metadata:
  name: log-sidecar
spec:
  selector:
    matchLabels:
      app: (([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?
  containers:
  - name: log-collector
    imagePullPolicy: Always
    image: xxx/fluentbit:0.2.7
    ports:
       - name: fluentbit-log
         containerPort: 80
    env:
      - name: FAST_SERVER
        value: 'https://xxx.xxx.com.cn'
      - name: FAST_ACCESS_KEY_ID
        value: 'xxx'
      - name: FAST_ACCESS_KEY_SECRET
        value: 'xxx'
      - name: FAST_PRODUCT_CODE
        value: 'rental'
      - name: FAST_APP_CODE
        value: 'xxxx'
      - name: FAST_LOG_NAME
        value: 'xxx'
      - name: FAST_ENABLE_METRICS
        value: 'on'
      - name: FAST_TAIL_PATH
        value: '/data/log/*/*.log'
    volumeMounts:
    - name: log-dir
      mountPath: /data/log
  volumes:
  - name: log-dir
    emptyDir: {}
```

注： 以上使用SidecarSet的是开源工具[kruise](https://openkruise.io/zh-cn/docs/sidecarset.html])的扩展.

## 总结：

1、Sidecar 容器适用于 比如监控、日志等 agent等场景；

2、Sidecar 容器和应用容器之间共享存储、网络、环境变量等资源；

## 参考文档

[microsoft sidecar](https://docs.microsoft.com/en-us/azure/architecture/patterns/sidecar#solution)

[openkruise](https://openkruise.io/zh-cn/index.html)