---
title: Prometheus 监控应用性能
date: 2019-07-15 10:21:58
tags: [性能监控]
categories: 监控
---
&emsp;&emsp; Prometheus 是一个开源的监控系统。它可以自动化的监听应用各性能指标的变化情况，并发出报警信息。了解它目的，是想把前端页面的性能指标记录到公司的 Prometheus 监控系统上，利用它监听前端页面各类异常。
<!--more-->
### 一、Prometheus 系统简介
[Prometheus](https://prometheus.io/) 是一个开源的服务监控系统，社区资源和开发者都很活跃。其主要原理是通过 HTTP 协议从远程的机器收集数据并存储在本地的[时序数据库](https://www.cnblogs.com/aiandbigdata/p/10052335.html)上。Prometheus 通过安装在远程机器上的 exporter (数据暴露)插件来收集监控数据。

#### Prometheus 特点
Prometheus 本身也是一个时序数据库，它通过 HTTP 的方式获取时序数据。Prometheus 自身的查询语言 PromQL 可多维度的查询并实时计算指标的值。通过 PromQL 提供的计算方法，可以自定义数据可视化的指标，以及报警临界值。它有四种数据类型，可针对不同场景使用不同数据类型。

#### Prometheus 系统的组成部分
{% asset_img "architecture.png" "Prometheus 架构" %}

在监控流程中，主要由三个部分组成：被监控的应用暴露性能指标(exporter)，promethues 应用采集性能指标(collector)，数据可视化分析界面(web UI)。详情参照下述：
1. Prometheus server: 用于抓取数据，并存储到时序数据库;
2. Prometheus exporter: 安装在监控目标的上，为 Prometheus server 提供数据抓取的接口;
3. Prometheus web UI: 提供数据可视化分析界面;
4. Alertmanager: 用于处理警报;
5. Pushgateway: 用于 job 推送;

### 二、Prometheus 监控流程图
{% asset_img "flowChart.png" "Prometheus flow chart" %}

#### Promethues server
主要负责数据采集和存储，提供 PromQL 查询语言的支持。可以通过 Prometheus 的 `.yml`文件中的`scrape_config` [(字段详情)](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config)来配置要抓取的应用指标地址。同时，Promethues 也会监控自身的健康情况，默认将指标暴露在自身的 `http://localhost:9090/metrics`。

#### Promethues exporter
参照[官方推荐的插件列表](https://prometheus.io/docs/instrumenting/clientlibs/)，由于本次监听的站点是 NodeJS 站点，所以选择 [prom-client](https://github.com/siimon/prom-client) 作为 exporter。
注意：被监听的应用需要暴露指标接口供 server 抓取。

#### Prometheus web UI
Grafana 可以连接多种类型的库，选择 Promethues 即可，默认监听 Promethues server 的9090`/metrics` 路径。

### 三、NodeJS 应用性能监控
使用 [prom-client](https://github.com/siimon/prom-client) 和 [node-prometheus-gc-stats](https://github.com/SimenB/node-prometheus-gc-stats) 收集 NodeJS 的性能指标。
* prom-client：收集服务端性能指标
* node-prometheus-gc-stats：垃圾回收相关指标统计

（prom-client 相当于一个exporter，将默认的指标暴露在 /metrics 接口，之后 Promethues service会根据 `.yml` 配置中的采集时间定期来这个接口采集数据信息，然后 web UI Grafana 再跟 Promethues server 进行同步）

#### prom-client 文档
一共支持四种数据格式：Histogram、Summary、Gauges 、Counters：

* __Histogram（柱状图）__ 统计数据的分布情况（比如 `Http_response_time` 的时间分布）
* __Summary（摘要）__ 主要用于表示一段时间内数据采样结果（请求持续的时间或响应大小）
* __Gauges（仪表盘）__ 最简单的度量指标，监测瞬间状态（监控硬盘容量或者内存的使用量）
* __Counters（计数器）__ 从数据量0开始累积计算，在理想状态下只能是永远的增长不会降低

常用的采集方法：
* collectDefaultMetrics() 返回 Promethues 的默认推荐指标，默认 10s 探测一次
* AggregatorRegsitry 聚合注册器：监听集群的性能指标（主进程和其产生的子进程）
  * clusterMetrics() 返回默认指标
  * [抓取所有进程的 metrics 只能在主进程上抓取，在子进程上获取不到 metrics](https://github.com/siimon/prom-client/issues/257)

收集到指标后，就可以利用 PromQL 进行计算了，计算时注意 PromQL __即时向量__ 和 __范围向量__ 两种向量的区别和转换：
````
    // 计算每分钟垃圾回收bytes数
    delta(nodejs_gc_reclaimed_bytes_total{gctype="Scavenge"}[1m])

    // 计算个页面5min以内的DomReady均值
    delta(FE_Timing_Performance_domReady_sum[5m])/delta(FE_Timing_Performance_domReady_count[5m])
````

#### ※[example-prometheus-nodejs](https://github.com/RisingStack/example-prometheus-nodejs)
&emsp;&emsp; 这个 demo 是一个完整的 prom-client + Promethues + grafana 监控示例，有助于理解整个监控流程。

### 四、前端异常记录实践结论
__并不推荐使用 Prometheus 系统来记录前端页面性能等信息。__
1. 从指标上来看，应用的基本性能指标：吞吐量、内存使用量、每秒请求数、请求平均耗时等。这些几乎都是“瞬时”值（由于时间窗口小，可看做瞬时值），而前端性能指标并不是“瞬时”，它更偏向于一段时间内的表现情况（时间窗口大）。Prometheus 系统主要用于监听应用的性能，它的数据类型更多是为应用服务。
* 应用性能特点：一个应用，多个指标；
* [前端页面的性能指标](https://kuro-p.github.io/2019/07/11/前端性能监控-Performance/#more)特点：一个页面，多个指标。多个页面。
2. 从数据类型上来看：
   * Gauges：不可以用来记录前端的性能表现。因为 Gauge 记录的某一刻的瞬时值，如果用来记录时间，则每次数据都会被最后访问的那名用户刷新；
   * Counter：计数器虽然可以记录前端某个页面的访问次数，但若页面路由中携带参数，或者结尾带时间戳，则会生成多个重复页面的 Counter，遇到爬虫还会生成大量无用路径，表现并不好；
   * Histogram、Summary：可以记录多个页面，多个指标；Histogram 和 Summary 很相似，只不过 Histogram 记录原始值，Summary 记录指标的各个占比。
3. 从可视化 Web UI 上来看：
公司 Prometheus 系统默认使用的可视化 UI 是 Grafana。之前尝试用 Histogram 来记录前端各页面的性能表现，在 Grafana 中用折线图可视化数据。一个指标对应一个折线图，但由于页面路由多个，导致各个折线图中折线过多难以分辨；若取所有页面该指标的均值或者最大值来展示，又不知道峰值是哪个页面产生的。

__综上可以看出，Prometheus 可以记录前端性能指标，但是受数据类型制约，它并不是最合适的。__

### 参考资料
* [Prometheus 官网](https://prometheus.io)
* [Prometheus 的数据类型介绍](https://blog.csdn.net/polo2044/article/details/83277299)
* [prom-client 监控示例](https://www.colabug.com/227611.html)
* [如何区分 Prometheus 中 Histogram 和 Summary 类型的 metrics?](https://www.cnblogs.com/aguncn/p/9920545.html)