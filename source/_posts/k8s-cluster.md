---
abbrlink: '0'
---
# Kubernetes 配置 kubeconfig 访问多个集群


## test集群（~/.kube/config）
```
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://localhost:6443
  name: test
contexts:
- context:
    cluster: test
    user: test-admin
  name: test
current-context: test
kind: Config
preferences: {}
users:
- name: test-admin
  user:
    client-certificate-data: CLIENT_CERTIFICATE_DATA
    client-key-data: CLIENT_KEY_DATA
```

## prod集群（~/.kube/config）
```
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://localhost:6443
  name: prod
contexts:
- context:
    cluster: prod
    user: prod-admin
  name: prod
current-context: prod
kind: Config
preferences: {}
users:
- name: prod-admin
  user:
    client-certificate-data: CLIENT_CERTIFICATE_DATA
    client-key-data: CLIENT_KEY_DATA
```

## 合并后（~/.kube/config）
```
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://localhost:6443
  name: test
- cluster:
    certificate-authority-data: CERTIFICATE_AUTHORITY_DATA
    server: https://localhost:6443
  name: prod
contexts:
- context:
    cluster: test
    user: test-admin
  name: test
- context:
    cluster: prod
    user: prod-admin
  name: prod
current-context: "" #默认集群设置为空
kind: Config
preferences: {}
users:
- name: test
  user:
    client-certificate-data: CLIENT_CERTIFICATE_DATA
    client-key-data: CLIENT_KEY_DATA
- name: prod
  user:
    client-certificate-data: CLIENT_CERTIFICATE_DATA
    client-key-data: CLIENT_KEY_DATA
```

## 查看集群
```
kubectl config get-contexts
```
## 切换集群
```
kubectl config use-context test
kubectl config use-context prod
```

注：如果想限制用户的 Namespace，可以在 context 中加入namespaces 配置.
```
- context:
    cluster: test
    user: test-admin
    namespace: default
  name: test
```

## 参考文档

[kubernetes官方文档](https://kubernetes.io/zh/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)