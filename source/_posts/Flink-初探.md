---
title: Flink 初探
date: 2019-11-14 14:58:06
tags: [大数据, 流处理]
categories: 大数据
---
Apache Flink 是一个分布式处理引擎，在有界或无界数据流上进行有状态的计算。工作时偶然接触到一点点，有些概念虽然有点抽象，但是思路却值得借鉴。本文记录用 Flink 实时求均值、水印生成、以及迟到的数据元触发计算更新等等，是一篇纯探索性文章。<del>用笔记形式记录，以便忘记。</del>
<!--more-->
### Flink 中文官网 
[https://flink.apachecn.org/docs/1.7-SNAPSHOT/#/](https://flink.apachecn.org/docs/1.7-SNAPSHOT/#/)

### 一、Flink 简介
Flink 是一个针对流数据和批数据的分布式处理引擎，代码主要是由 Java 实现，部分代码是 Scala。它可以处理有界的批量数据集、也可以处理无界的实时数据集。对 Flink 而言，其主要处理的场景就是流数据。<br/>

### 二、流处理和批处理的区别
__批处理__ 特点：离线、单次处理的数据量大、处理速度慢、非实时计算。常见的批处理就是数据库深夜定时跑任务，因为批量计算会占用大量资源。
__流处理__ 特点：在线，单次处理数据量小、处理速度快、实时计算。常见的应用场景就是监控、统计、实时推荐等。

### 三、学习目标
用 Flink 消费已有数据源，实时计算数据均值，并允许数据元延迟到来时，重新触发计算。

### 四、涉及到的名词概念
1. __窗口__ (Windows)：对某段数据流进行统计，即统计区间；Windows 可以是时间驱动的（例如：每30秒）或数据驱动（例如：每100个数据元）。
2. __时间__ (Time)：程序中引用的时间；Flink 支持三种时间：事件时间、摄取时间和处理时间。
3. __算子__ (Operator)：Flink 内部提供的时间/数据流/数据元的处理函数。
4. __时间戳__ (TimeStamp)/__水印__ (WaterMark)：使用数据源的时间或者系统时间为到来的数据元加上时间戳；数据流加上水印标记，为了等下个数据元到来时知道该数据元是否应该被包含在当前次计算中。
__注：Watermark 是随数据产生的，窗口时间现在处于什么位置看 Watermark，只有新产生的一条数据超出窗口长度，这个窗口才会触发计算。(当使用事件时间窗口时，可能会发生数据元迟到的情况，则必须为数据流设置时间戳和水印)__
   
#### 允许迟到 allowedLateness
只要应该属于此窗口的第一个数据元到达，就会创建一个窗口，当时间（事件或处理时间）超过其结束时间戳加上用户指定 allowed lateness 时，窗口将被完全删除。
__allowedLateness 用来设置窗口销毁时间__ ，而 waterMark 是用来设置窗口激活时间。当时延迟时间超过 allowedLateness 设置的时间，这个计算窗口就会被销毁，开始下一个窗口，即使被销毁的窗口还没有触发计算。

#### 窗口函数
Flink 的窗口函数会暴露出数据流不同状态时的处理函数，具体的高级操作或者运算例如聚合、求均值等函数需要我们自己去实现。
例如聚合窗口 `stream.aggregate` 的参数 AggregateFunction <IN, ACC, OUT>，具有三种的类型：输入类型(IN)、累加器类型(ACC)和输出类型(OUT)。
使用 AggregateFunction 求均值（示例代码来自[官网](https://flink.apachecn.org/docs/1.7-SNAPSHOT/#/27?id=window-functions)）：
````java
    private static class AverageAggregate
    implements AggregateFunction<Tuple2<String, Long>, Tuple2<Long, Long>, Double> {
    @Override
    public Tuple2<Long, Long> createAccumulator() {
      return new Tuple2<>(0L, 0L);
    }

    @Override
    public Tuple2<Long, Long> add(Tuple2<String, Long> value, Tuple2<Long, Long> accumulator) {
      return new Tuple2<>(accumulator.f0 + value.f1, accumulator.f1 + 1L);
    }

    @Override
    public Double getResult(Tuple2<Long, Long> accumulator) {
      return ((double) accumulator.f0) / accumulator.f1;
    }

    @Override
    public Tuple2<Long, Long> merge(Tuple2<Long, Long> a, Tuple2<Long, Long> b) {
      return new Tuple2<>(a.f0 + b.f0, a.f1 + b.f1);
    }

    DataStream<Tuple2<String, Long>> input = ...;

    input
        .keyBy(<key selector>)
        .window(<window assigner>)
        .aggregate(new AverageAggregate());
    }
````

### 五、遇到的问题
* 数据流过滤后，只剩下被过滤的数据：
  * __SingleOutputStreamOperator__ 旁路分支：这个分支用来获取被过滤掉的数据，并不是过滤后的数据。
* 给数据流设置时间戳之后，迟到的数据没有被抛弃：
  * __stream.assignTimestampsAndWatermarks__ 定期生成水印：最简单的特殊情况是给定源任务看到的时间戳按升序发生的情况。在这种情况下，当前时间戳始终可以充当水印，因为没有更早的时间戳会到达。且生成的时间戳会覆盖事件原有的，若存在迟到的数据元，用这个方法，则数据不会被抛弃。
  * __BoundedOutOfOrdernessTimestampExtractor__ ：Flink 提供此参数为固定数量的迟到者分配时间戳和水印。若有数据元可能迟到的场景，请应用此方法。
* [设置的水印时间戳，超时告警，但是数据没有被丢弃？](https://stackoverflow.com/questions/50114412/flink-watermark-and-triggers-late-elements-not-discarded-on-event-time)
* [最新记录没有被统计，只有下一条数据写入时，之前的数据才会被触发统计？](https://developer.aliyun.com/ask/128431?spm=a2c6h.13159736)

### 六、数据下沉 Data Sink
Flink 可以自己指定数据源连接器，以及数据下沉(接收)目标。从 Flink 官网上来看连接器支持 Kalfa、Elasticsearch、HDFS、RabbitMQ 等等，公司已有 RabbitMQ 数据源，使用 RabbitMQ sink 接收数时，注意事件消费者不要和事件生产者的队列名不要相同，否则会报错。

### 参考链接
* [http://www.54tianzhisheng.cn/](http://www.54tianzhisheng.cn/)
* [Flink 水印机制到底怎么回事](https://bbs.csdn.net/topics/392567642?list=70723145)
* [Flink 水印机制](https://www.cnblogs.com/starzy/p/11439997.html)
* [Flink实战--如何使用水印](https://blog.csdn.net/aA518189/article/details/85233247)
* [Flink Window 的 Timestamps/Watermarks 和 allowedLateness 的区别](https://www.cnblogs.com/jiang-it/p/9280946.html)
* [Flink 零基础实战教程：如何计算实时商品](http://wuchong.me/blog/2018/11/07/use-flink-calculate-hot-items/)
* [《从0到1学习Flink》-- Flink读取 Kafka 数据写入到 RabbitMQ](https://cloud.tencent.com/developer/article/1419588)