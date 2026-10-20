<a id="jsip-exchange"></a>

# JSIP Exchange 中文说明

> 对照原文：[README.md](README.md)。正文按原章节顺序翻译；代码、终端输出和标识符保留原样。
> 译注：这是教学项目。文档有些地方描述目标行为，实际是否实现请核对 `.ml`。当前 Bot_runtime 提供回调和 context，BBO/库存由各 bot 自己维护；原文表格对此有简化描述。

<a id="tushare-historical-a-share-data"></a>

## Tushare 历史 A 股数据

历史行情应用把整数 CSV 导出加载为 `Jsip_market_data.Historical_bar.t`，再以确定性的顺序交给 OCaml callback。真实抓取/导出命令、接口、单位和离线测试见 [Tushare 历史接入中文版](doc/tushare-history.zh-CN.md)。

```sh
opam exec -- dune exec jsip-historical-replay -- \
  -input ../data/exports/jsip_a_share_bars.csv
```

这是用 OCaml 编写的简化证券交易所。项目将逐层扩展和改进，从基础数据结构到网络协议。

<a id="what-is-an-exchange"></a>

## 什么是交易所？

交易所是买卖双方交易股票、债券等金融工具的市场。它自身不买卖，而是撮合买卖双方。

参与者想以 $150.00 买 100 股 AAPL[^1]，就提交订单。若已有卖方愿意以不高于该价卖出，订单就会成交；否则进入订单簿等待合适卖方。

订单簿是核心数据结构，有两侧：

- **Bid 买侧：** 理想排列为价格从高到低，最高买价是 best bid。
- **Ask 卖侧：** 理想排列为价格从低到高，最低卖价是 best ask，也叫 offer。

最优卖价减最优买价是 spread（买卖价差）。新买单愿意至少支付最优卖价，或新卖单愿意接受不高于最优买价，就会与对手挂单成交。BBO 是 best bid and offer，表示当前最优买卖报价。

<a id="architecture"></a>

## 架构

系统按依赖关系分层：

| 层 | 目录 | 职责 |
| --- | --- | --- |
| 应用 | `app/server/client/market_maker/bots/scenarios/scenario_runner/monitor` | 服务端、客户端、做市商、bots、场景、启动命令、终端监控 |
| Bot 生态 | `lib/bot_runtime/fundamental/news_injector` | 运行支架、模拟基本面价格、预设消息冲击 |
| 网关 | `lib/gateway` | 客户端与交易所通信 |
| 订单簿和撮合 | `lib/order_book` | 维护订单并执行成交 |
| 基础类型 | `lib/types` | Side、Price、Size、Symbol、Order、Fill 等 |
| 测试支架 | `lib/test_harness` | 可复用测试基础设施 |

<a id="core-types-libtypessrc"></a>

### 基础类型（`lib/types/src/`）

| 模块 | 作用 |
| --- | --- |
| `Side` | Buy 或 Sell |
| `Price` | 以整数分表示的固定点价格 |
| `Size` | 订单数量，语义明确的 int 封装 |
| `Symbol` | 证券标识，如 AAPL |
| `Participant` | 可提交订单的参与者，以唯一字符串名字标识 |
| `Order_id` | 撮合引擎分配的内部订单编号 |
| `Time_in_force` | 有效方式：Day、Ioc |
| `Order` | 提交前 Request 和带可变剩余数量的在簿 Order |
| `Fill` | 成交价格、数量、双方信息 |
| `Level` | 一档价格及汇总数量，供 Bbo/Book 使用 |
| `Bbo` | 买卖两侧最优 Level |
| `Book` | 含价位与 BBO 的只读快照，订单簿查询 RPC 返回它 |
| `Exchange_event` | 接受、成交、取消、拒绝、BBO 更新、公开成交报告 |
| `Cancel_reason` | 取消原因 |

Day 可挂单，原文目标是未成交部分在收盘取消；IOC 尽量立即成交，剩余立即取消，绝不挂单。当前收盘处理仍是练习目标，请核对实现。

<a id="order-book--matching-engine-liborder_booksrc"></a>

### 订单簿与撮合引擎（`lib/order_book/src/`）

`Order_book` 管理单个 symbol 的买卖侧，提供增删查和 find_match。
`Matching_engine` 管理多个订单簿，submit 分配 ID、运行撮合并返回事件。

撮合循环反复调用 find_match：每次减少双方剩余数量，移除完全成交的挂单，生成 Fill 和 Trade_report。结束后 Day 剩余挂簿，IOC 剩余取消。

submit 是同步状态转换。网络侧 Exchange_server 把请求放进有界 Pipe，后台任务依次读取、调用 submit、交给 Dispatcher 分发。队列的背压约束请求积压，撮合引擎不等待慢网络 I/O。

**已知限制：** 当前 find_match 返回列表中第一条可成交订单，而非价格最优订单；价格优先测试展示了此问题，后续练习会修复。

<a id="gateway-libgatewaysrc"></a>

### 网关（`lib/gateway/src/`）

负责文本命令解析、RPC 通信和事件路由。

| 模块 | 作用 |
| --- | --- |
| Protocol | 将 `BUY AAPL 100 150.00 as Alice` 解析为请求，并格式化事件 |
| Exchange_server | 组装引擎、有界请求队列、dispatcher、RPC |
| Rpc_protocol | 定义 Async RPC |
| Dispatcher | 按 symbol、审计订阅和参与者路由事件 |
| Session | 参与者身份及其出站事件 Pipe；session feed RPC 是第二部分练习，目前个人事件仍打印在服务器 stdout |

<a id="bot-ecosystem-libbot_runtime-libfundamental-libnews_injector"></a>

### Bot 生态（`lib/bot_runtime/`、`lib/fundamental/`、`lib/news_injector/`）

这些自动参与者为场景提供市场活动，与引擎并列，不属于引擎内部。

- Bot_runtime：单 bot 的 context 和回调支架，周期性调用 on_tick，把事件送给 on_event。原文称它追踪 BBO/库存，当前实现把该状态留给 bot。
- Fundamental_oracle：每个 symbol 一个 Ornstein–Uhlenbeck 模拟价格过程，给 bot 提供参考“真实价值”，seed 控制可复现性。
- News_injector：相对场景启动时间，按预设偏移给 oracle 注入财报意外或闪崩等冲击。

Bot 与普通客户用同样的 RPC。Bot_runtime.create 接收 submit/cancel 闭包，场景运行器把它们接到本地连接的 RPC。

<a id="applications-app"></a>

### 应用（`app/`）

| 应用 | 作用 |
| --- | --- |
| server | TCP RPC 服务器；可预置做市商挂单或让两个做市商循环交易 |
| client | 交互客户端，支持 BUY、SELL、BOOK、SUBSCRIBE |
| market_maker | 围绕合理价值预置挂单的做市商库 |
| bots | 每个 bot 一个模块，初始为空，后续添加 |
| scenarios | Calm_day、Active_day、Earnings_shock、Flash_crash 等；符合 Scenario.S 并注册到 all |
| scenario_runner | 选择场景，启动交易所、oracle、新闻和 bots |
| monitor | bonsai_term 终端界面，订阅审计流，按类别和颜色过滤展示事件 |

<a id="test-harness-libtest_harnesssrc"></a>

### 测试支架（`lib/test_harness/src/`）

- Harness：symbol/参与者常量、buy/sell 构造器、打印器、Show 过滤器、不自动打印行情的 quiet 版本、每种事件一个的 sample_events。
- E2e_helpers：在系统分配端口上启动真实服务器，提供 with_server/connect_as/connection/rpc_submit/rpc_book。session feed 未接通时个人事件仍以 `[for <participant>]` 打到服务器 stdout；接通后应由辅助函数读取并返回。

<a id="building-and-running"></a>

## 构建与运行

```sh
# Build everything
dune build

# Run all tests
dune runtest

# Format the code
dune fmt

# Run the server and client (in separate terminals):

# Run the exchange server with a market maker pre-seeding the book
dune exec app/server/bin/main.exe -- -port 12345 -seed-market-maker

# Or run two market makers trading back and forth, for sustained traffic
dune exec app/server/bin/main.exe -- -port 12345 -trade-back-and-forth

# Run an interactive order-entry client
dune exec app/client/bin/main.exe -- -port 12345 -name Alice

# Boot a named scenario (exchange + bots + simulated news) on one process.
# NOTE: the named scenarios are currently TODO stubs; filling them in is
# part of the project, so this will raise until they're implemented.
dune exec app/scenario_runner/bin/main.exe -- -scenario calm-day -port 12345 -seed 0

# Watch the exchange's audit log in a filterable TUI
dune exec app/monitor/bin/main.exe -- -host localhost -port 12345
```

> 译注：本机需要 `opam exec --` 才能使用正确依赖环境；全仓库仍有工具链版本问题，历史回放目标可单独构建。以上原始命令未改写。

<a id="client-commands"></a>

### 客户端命令

```
BUY AAPL 100 150.00              Buy 100 shares at $150.00 (Day order)
SELL TSLA 50 200.00 IOC          Sell 50 shares IOC
BUY AAPL 100 150.00 as Bob       Specify participant name
BOOK AAPL                        Show the order book
SUBSCRIBE AAPL                   Stream market data updates
```

依次表示买入 100 股、IOC 卖出 200 股、指定参与者、查看订单簿、订阅行情。

<a id="what-youll-see-when-you-submit-orders"></a>

### 提交订单后会看到什么？

目前缺少把接受、成交、取消、拒绝推送给指定客户的 session feed RPC 和登录流程，这是第二部分练习。Session 模块和分派逻辑已存在。

当前 `push_to_session` 占位实现以 `[for <participant>]` 为前缀打印服务器 stdout，所以应单独打开服务器终端观察。

公开 BBO 更新和 Trade_report 已有推送通道，使用 `SUBSCRIBE <symbol>` 订阅。

<a id="testing"></a>

## 测试

项目使用 let%expect_test，但检查方式有三类：

- **输出比较：** 执行情景、打印结果，与源文件 expect 块比较。适合撮合交互和订单簿状态。变化时失败并显示 diff；确认正确后 promote。
- **值断言：** `[%test_result]` 直接比较值。无打印时不必写 expect 块。失败用 sexp 展示实际/预期值；异常检查可用 require_does_raise/require_does_not_raise。
- **协议结构：** test_rpc_shapes 对网络类型的 bin_io 布局生成摘要，锁定 RPC 的名字、版本及类型结构。字段、构造子或嵌套类型变化会改变摘要。它验证协议，而非运行行为；变更后先核对再 promote。

```sh
# Run tests
dune runtest

# If an expect test fails with new (correct) output, promote it
dune promote
```

<a id="test-organization"></a>

### 测试组织

| 文件 | 测试内容 |
| --- | --- |
| lib/types/test/test_side.ml | 买卖翻转、符号、可成交性、解析 |
| lib/types/test/test_price.ml | 价格构造、算术、格式和比较 |
| lib/types/test/test_symbol.ml | symbol 构造和校验 |
| lib/types/test/test_order_id.ml | ID 生成及顺序 |
| lib/types/test/test_time_in_force.ml | 解析与是否可挂单 |
| lib/types/test/test_order.ml | 订单构造、成交更新、验证 |
| lib/types/test/test_fill.ml | 成交名义金额 |
| lib/order_book/test/test_order_book.ml | 增删查、最优价、find_match |
| lib/order_book/test/test_matching_engine.ml | 撮合、IOC、多 symbol、行情事件 |
| lib/gateway/test/test_protocol.ml | 命令解析、错误、格式化 |
| lib/gateway/test/test_end_to_end.ml | 真实服务器、RPC、行情订阅 |
| lib/gateway/test/test_rpc_shapes.ml | 网络类型摘要 |
| lib/fundamental/test/test_fundamental_oracle.ml | seed 确定性、均值回归、冲击 |
| lib/news_injector/test/test_news_injector.ml | 定时冲击 |
| lib/bot_runtime/test/test_bot_runtime.ml | 原文称状态和事件；当前主要检查 runtime/context 行为 |
| app/market_maker/test/test_market_maker.ml | 做市商预置挂单及与其成交 |
| app/bots/test/test_bots.ml | mock context 记录 submit/cancel 的测试支架 |
| app/monitor/test/test_event_log.ml | 分类、文本及组合过滤、颜色、BBO 快照 |
| app/monitor/test/test_controller.ml | 按键、过滤标签、文本编辑状态机 |

<a id="benchmarks"></a>

### 基准测试

订单簿及撮合 benchmark 位于 `lib/order_book/bench/bench_order_book.ml`。

```sh
# Run benchmarks (takes ~4 minutes with default quota)
dune exec lib/order_book/bench/bench_order_book.exe -- -ascii -quota 5

# Quick run (shorter quota, less stable results)
dune exec lib/order_book/bench/bench_order_book.exe -- -ascii -quota 1
```

<a id="what-the-benchmarks-measure"></a>

#### 各 benchmark 测什么？

| 名字 | 测量 |
| --- | --- |
| find_match (n=X) | 可成交新单到达时查找挂单，属于热路径 |
| find_match_miss (n=X) | 没有可成交挂单时的扫描，暴露最坏情况 |
| best_bid_offer (n=X) | 最优买卖价格及数量 |
| add+remove (n=X) | 插入再立即删除的状态修改成本 |
| submit_ioc_cross (n=X) | IOC 穿过卖一：撮合、成交、BBO 和事件构造 |
| submit_ioc_miss (n=X) | IOC 无成交时的提交固定成本 |
| submit_sweep_X_levels | 大单扫过多档的最坏撮合 |
| find_match_alloc (n=X, Y words/call) | 与 find_match 相同，在名字中标明每次 minor heap 分配量，越少越好 |

n 是在簿挂单数，通常测 10、50、100、500，以观察规模增长。

<a id="how-to-read-the-output"></a>

#### 如何读输出？

```
┌───────────────────────────────────────────┬──────────┬──────────┬──────────┬──────────┬──────────────┬────────────┬────────────┐
│ Name                                      │  mGC/Run │ mjGC/Run │ Prom/Run │ mjWd/Run │     Time/Run │    mWd/Run │ Percentage │
├───────────────────────────────────────────┼──────────┼──────────┼──────────┼──────────┼──────────────┼────────────┼────────────┤
│ find_match (n=10)                         │  0.01e-3 │          │          │          │      23.93ns │     15.00w │            │
│ find_match (n=50)                         │  0.01e-3 │          │          │          │      23.39ns │     15.00w │            │
│ find_match (n=100)                        │  0.01e-3 │          │          │          │      22.13ns │     15.00w │            │
│ find_match (n=500)                        │  0.01e-3 │          │          │          │      22.96ns │     15.00w │            │
│ find_match_miss (n=10)                    │  0.01e-3 │          │          │          │     134.62ns │     13.00w │      0.05% │
│ find_match_miss (n=50)                    │  0.01e-3 │          │          │          │     395.48ns │     13.00w │      0.15% │
│ find_match_miss (n=100)                   │  0.01e-3 │          │          │          │     773.19ns │     13.00w │      0.30% │
│ find_match_miss (n=500)                   │  0.01e-3 │          │          │          │   4_510.21ns │     13.00w │      1.74% │
│ best_bid_offer (n=10)                     │  0.01e-3 │          │          │          │     180.96ns │     13.00w │      0.07% │
│ best_bid_offer (n=50)                     │  0.01e-3 │          │          │          │     837.88ns │     13.00w │      0.32% │
│ best_bid_offer (n=100)                    │  0.01e-3 │          │          │          │   1_573.77ns │     13.00w │      0.61% │
│ best_bid_offer (n=500)                    │  0.01e-3 │          │          │          │   7_674.52ns │     13.00w │      2.96% │
│ add+remove (n=100)                        │  0.49e-3 │          │    0.25w │    0.25w │   1_279.04ns │    513.00w │      0.49% │
│ submit_ioc_cross (n=10)                   │  0.20e-3 │          │          │          │   1_305.20ns │    210.00w │      0.50% │
│ submit_ioc_cross (n=50)                   │  0.39e-3 │          │          │          │   4_357.86ns │    410.00w │      1.68% │
│ submit_ioc_cross (n=100)                  │  0.63e-3 │          │    0.30w │    0.30w │   8_726.96ns │    660.00w │      3.36% │
│ submit_ioc_cross (n=500)                  │  2.55e-3 │  0.03e-3 │    6.16w │    6.16w │  37_524.33ns │  2_660.00w │     14.47% │
│ submit_ioc_miss (n=10)                    │  0.07e-3 │          │          │          │     502.83ns │     76.00w │      0.19% │
│ submit_ioc_miss (n=50)                    │  0.07e-3 │          │          │          │   2_174.09ns │     76.00w │      0.84% │
│ submit_ioc_miss (n=100)                   │  0.07e-3 │          │          │          │   4_541.80ns │     76.00w │      1.75% │
│ submit_ioc_miss (n=500)                   │  0.07e-3 │          │          │          │  20_886.92ns │     76.00w │      8.05% │
│ submit_sweep_10_levels                    │  1.40e-3 │          │    0.21w │    0.21w │   4_802.63ns │  1_464.00w │      1.85% │
│ submit_sweep_50_levels                    │ 11.39e-3 │  0.04e-3 │    7.64w │    7.64w │  68_262.45ns │ 11_924.00w │     26.31% │
│ submit_sweep_100_levels                   │ 34.70e-3 │  0.22e-3 │   47.31w │   47.31w │ 259_412.14ns │ 36_249.00w │    100.00% │
│ find_match_alloc (n=100, 12.0 words/call) │  0.01e-3 │          │          │          │      20.79ns │     15.00w │            │
└───────────────────────────────────────────┴──────────┴──────────┴──────────┴──────────┴──────────────┴────────────┴────────────┘
```

OCaml 自动管理内存：新值廉价地分配到 minor heap；minor GC 回收不再需要的值，把存活者晋升到 major heap；长期值最终由更昂贵的 major GC 处理。分配虽快，每个分配的 word 都可能形成后续 GC 工作，故分配多仍可能成为瓶颈。详见 [RWO GC 章节](https://dev.realworldocaml.org/garbage-collector.html)。

- **mGC/Run：** 每次调用平均触发多少次 minor GC。例如 34.70e-3 约每 29 次调用一次，越高压力越大；许多测试约每十万次一次。
- **mjGC/Run：** 每次调用的 major GC 次数，更昂贵，即使数值小也值得关注。
- **Prom/Run：** 每次从 minor 晋升到 major 的 words，通常接近 mjWd/Run。
- **mjWd/Run：** 每次在 major heap 分配的 words，空白通常表示没有。
- **Time/Run：** 每次平均墙钟时间，常以 ns 表示，越低越好。
- **mWd/Run：** 每次 minor heap 分配的 words。示例 sweep 100 档约 36,249 words，而 find_match 只有 15。
- **Percentage：** 相对本轮最慢 benchmark 的时间比例，便于横向比较。

<a id="what-to-look-for"></a>

#### 应关注什么？

**随规模变化：** 比较不同 n 的同一项。n 从 10 到 500，时间从 100ns 到 4500ns，说明线性扫描；更合适的有序结构可能做到 O(log n) 或 O(1)。

**分配压力：** 快操作若反复大量分配仍可能造成 GC 暂停和延迟抖动。find_match_alloc 在名字中报告精确 words/call。

**前后比较：**

```sh
dune exec lib/order_book/bench/bench_order_book.exe -- -ascii -quota 5 > before.txt
# ... make your optimization ...
dune exec lib/order_book/bench/bench_order_book.exe -- -ascii -quota 5 > after.txt
diff before.txt after.txt
```

<a id="tips-for-stable-results"></a>

#### 稳定测量的建议

- quota 至少 5 秒，短测量噪声更大。
- 关闭无关程序，减少 CPU 干扰。
- 重复运行，确认一致后下结论。
- 关注相对变化，如快两倍、分配少十倍，不迷信跨机器的绝对纳秒数。

<a id="writing-tests"></a>

### 编写测试

使用 Harness 写简洁场景：

```ocaml
open Jsip_test_harness

let%expect_test "my scenario" =
  let t = Harness.create () in
  (* Bob places a sell *)
  Harness.submit_ t (Harness.sell ~price_cents:15000 ~participant:Harness.bob ());
  (* Alice buys — should cross *)
  Harness.submit_ t (Harness.buy ~price_cents:15000 ());
  (* Check the book state *)
  Harness.print_book t Harness.aapl;
  [%expect {|
    ACCEPTED id=1 AAPL SELL 100@$150.00 DAY
    BBO AAPL bid=- ask=$150.00 x100
    ACCEPTED id=2 AAPL BUY 100@$150.00 DAY
    FILL fill_id=1 AAPL $150.00 x100 aggressor=2(Alice) BUY resting=1(Bob)
    TRADE AAPL $150.00 x100
    BBO AAPL bid=- ask=-
    === AAPL ===
      BIDS: (empty)
      ASKS: (empty)
      BBO: - / -
  |}]
;;
```

submit_ 会打印全部事件，包括行情。只关心撮合时，用 submit_quiet_ 隐去行情事件。

<a id="how-to-find-your-way-around"></a>

## 如何找到代码位置？

每个模块的 mli 描述公开 API，应先读接口。用编辑器搜索练习涉及的类型和函数，沿 docstrings 定位实现。

<a id="glossary"></a>

## 术语表

- **Aggressor 主动方：** 新到达、触发撮合的订单一方。
- **Ask 卖价/卖单：** 卖出意愿，卖侧最低价格最优；也叫 offer。
- **BBO 最优买卖报价：** 最高买价与最低卖价，描述可立即交易的两侧价格。
- **Bid 买价/买单：** 买入意愿，买侧最高价格最优。
- **Bot 自动交易程序：** 借助 Bot_runtime 的周期回调和 context 提交订单；BBO/库存记账由策略负责。
- **Book depth 订单簿深度：** 两侧全部价位及每档总数量。
- **Cancel 撤单：** 成交前移除挂单，剩余数量不能再撮合。
- **Cross 可成交交叉：** 新单价格足够积极，能与对手挂单成交。
- **Day order 当日有效单：** 目标是收盘前有效，未成交自动取消。
- **Fair value 合理价值：** 对标的真实价值的估计，做市商据此报价。
- **Fill 成交：** 双方全部或部分执行，部分成交减少剩余量。
- **Fundamental price 模拟基本面价格：** 场景中的参考价值，独立于簿中报价；bot 读 oracle，news injector 可制造阶跃变化。
- **FOK 全成或取消：** 必须立刻全部成交，不允许部分成交。
- **GTC 撤销前有效：** 直到成交或显式取消，可跨交易时段。
- **Half-spread 半价差：** 价差的一半；参考价 $150、半价差 $0.10，对应买 $149.90、卖 $150.10。
- **IOC 立即成交否则取消：** 尽量成交，剩余取消，不挂簿。
- **Inventory 库存/净持仓：** 买入减卖出的净数量；正数多头，负数空头。
- **Liquidity 流动性：** 可供成交的挂单；多且价差窄通常易交易。
- **Market data 行情：** 公开成交和 BBO 等匿名信息，不透露参与者。
- **Market maker / Market making 做市商/做市：** 持续提供买卖两侧报价，尝试赚价差，同时承担库存价格风险。
- **Matching engine 撮合引擎：** 接收订单、维护簿、决定成交并生成 Fill。
- **Notional 名义金额：** 价格乘数量，例如 100 股 × $150.25 = $15,025。
- **Order book 订单簿：** 某 symbol 的全部未成交挂单，分买卖两侧。
- **P&L 损益：** 交易获得的净盈亏，不能与交易本金现金流混淆。
- **Position 持仓：** 某 symbol 的净数量；买增卖减，+100 表示多头 100 股。
- **Price level 价位：** 一个价格下可以挂多条订单。
- **Price-time priority 价格时间优先：** 先更积极价格，再同价先到先成交。
- **Remaining size 剩余数量：** 100 股成交 30 后剩 70。
- **Resting order 挂单：** 已在簿中等待成交的订单。
- **Scenario 场景：** 可复现的 symbols、oracle、新闻、bots 配置，由 runner 组装。
- **Self-trade 自成交：** 同一参与者买卖互相成交，会制造误导活动。
- **Spread 买卖价差：** 最优卖价减最优买价，越窄通常报价越紧。
- **Sweep 扫单：** 大额主动单连续成交多个越来越差的档位。
- **Tick 最小价格变动单位：** 本交易所为一分；此处与 bot 定时 tick 回调是不同含义。
- **TIF 订单有效方式：** Day、IOC、FOK、GTC 等。
- **Trade print / Trade report 公开成交记录：** 只含证券、价格、数量，不含参与者身份。

<a id="key-concepts"></a>

## 核心概念

<a id="price-time-priority"></a>

### 价格时间优先

对手侧所有可成交挂单先按价格优先，再同价按到达时间。例如卖单 A：$10×100 最先到；B：$10×50 后到；C：$10.05×200。买价 $10.05 先成交 A，再 B，再 C。

<a id="aggressor-vs-resting"></a>

### 主动方与挂单方

主动方是触发撮合的新单，挂单方已在簿中。成交使用挂单价格，通常比主动方的限价更有利：买方可能少付，卖方可能多收。

<a id="market-data"></a>

### 行情

提交订单后可能发出：

- Trade_report：匿名公开成交价格和数量。
- Best_bid_offer_update：簿改变后的最新 BBO，仅实际 BBO 变化时发出。

订阅者看见成交和价位，看不见交易者身份。

<a id="async-rpcs"></a>

### Async RPC

使用 Jane Street Async RPC：

- 普通 Rpc.Rpc：submit_order_rpc 在请求进入队列后返回 `unit Or_error.t`。真正接受/成交/拒绝应异步走 session feed，目前仍打印 stdout；book_query_rpc 返回 Book.t。
- 流式 Rpc.Pipe_rpc：market_data_rpc 推送指定 symbols 的 BBO/Trade_report；audit_log_rpc 推送未过滤事件全集，供监控而非普通客户使用。

[^1]:
    AAPL 是 Apple, Inc. 的股票代码。参见 [Investopedia](https://www.investopedia.com/terms/s/stocksymbol.asp)。
