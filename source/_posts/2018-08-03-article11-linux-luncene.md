---
layout: post
title: lucene查询语法，适用于ELk：kibana查询
author: owelinux
categories: linux
tags: lucene ELK kibana
excerpt: lucene查询语法，适用于ELk：kibana查询.
mathjax: true
abbrlink: 654c9140
date: 2018-08-03 11:49:54
---

* content
{:toc}

# lucene查询语法，适用于ELk：kibana查询
Kibana在ELK中扮演着数据可视化角色，用来查询及展示数据；
Elasticsearch查询采用的是luncene搜索引擎，其4过滤查询语法和lucene一致。

![](http://owelinux.github.io/images/2018-08-03-article11-linux-luncene/elk-lucene.png)

[Kibana官方在线演示](http://demo.elastic.co/app/kibana#/discover)

## 字段搜索
Lucene支持实时数据。执行搜索时，您可以指定字段，也可以使用默认字段。字段名称和默认字段是特定于实现的。

```
限定字段全文搜索：field:value
精确搜索：关键字加上双引号 filed:"value"
http.code:404 搜索http状态码为404的文档
```
字段本身是否存在
```
_exists_:http：返回结果中需要有http字段
_missing_:http：不能含有http字段
```

## 通配符搜索
Lucene支持单个术语内的单个和多个字符通配符搜索（不在短语查询中）。

```
? 匹配单个字符
* 匹配0到多个字符
te?t,test*,te*t
```
注意：您不能使用*或？符号作为搜索的第一个字符。

## 正则表达式搜索
Lucene支持正向表达式搜索.
```
name:/joh?n(ath[oa]n)/
```
## 模糊搜索
```
quikc~ brwn~ foks~
~:在一个单词后面加上~启用模糊搜索，可以搜到一些拼写错误的单词
first~ 这种也能匹配到 frist
```
还可以设置编辑距离（整数），指定需要多少相似度
```
cromm~1 会匹配到 from 和 chrome
默认2，越大越接近搜索的原始值，设置为1基本能搜到80%拼写错误的单词
```
## 近似搜索
在短语后面加上~，可以搜到被隔开或顺序不同的单词
```
"where select"~5 表示 select 和 where 中间可以隔着5个单词，可以搜到 select password from users where id=1
```

## 范围搜索

数值/时间/IP/字符串 类型的字段可以对某一范围进行查询
```
length:[100 TO 200]
sip:["172.24.20.110" TO "172.24.20.140"]
date:{"now-6h" TO "now"}
tag:{b TO e} 搜索b到e中间的字符
count:[10 TO *] * 表示一端不限制范围
count:[1 TO 5} [ ] 表示端点数值包含在范围内，{ } 表示端点数值不包含在范围内，可以混合使用，此语句为1到5，包括1，不包括5
可以简化成以下写法：
age:>10
age:<=10
age:(>=10 AND <20)
```
## 优先级
使用^使一个词语比另一个搜索优先级更高，默认为1，可以为0~1之间的浮点数，来降低优先级
```
quick^2 fox
```
## 布尔运算符搜索
布尔运算符允许通过逻辑运算符组合术语。Lucene支持AND，“+”，OR，NOT和“ - ”作为布尔运算符（注意：布尔运算符必须是ALL CAPS）。

OR
```
"jakarta apache" jakarta
or
"jakarta apache" OR jakarta
```
AND
```
"jakarta apache" AND "Apache Lucene"
```
+:搜索结果中必须包含此项
```
+jakarta lucene
```
NOT
```
"jakarta apache" NOT "Apache Lucene"
NOT "jakarta apache"
```
-：不能含有此项
```
"jakarta apache" -"Apache Lucene"
```
## 分组搜索
Lucene支持使用括号将子句分组以形成子查询。如果要控制查询的布尔逻辑，这可能非常有用。
```
(jakarta OR apache) AND jakarta
```
## 字段分组搜索
Lucene支持使用括号将多个子句分组到单个字段。
```
title:(+return +"pink panther")
host:(baidu OR qq OR google) AND host:(com OR cn)
```
## 转义特殊字符搜索
Lucene支持转义属于查询语法的特殊字符。
```
+ - = && || > < ! ( ) { } [ ] ^ " ~ * ? : \ /
以上字符当作值搜索的时候需要用\转义
\(1\+1\)\=2用来查询(1+1)=2
```
# 参考：
> * [https://lucene.apache.org/core/5_2_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html](https://lucene.apache.org/core/5_2_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html)
> * [https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html#query-string-syntax](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html#query-string-syntax)
> * [https://segmentfault.com/a/1190000002972420#articleHeader10](https://segmentfault.com/a/1190000002972420#articleHeader10)
