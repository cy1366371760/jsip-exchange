<a id="jsip-exercises---part-4"></a>

# JSIP 练习：第四部分

> 对照：[英文原文](exercises-part-4.md)。这是性能练习目标，不是当前已完成清单；原文假设已完成 Map 订单簿、客户端 ID、登录和取消，本地代码应分别核对。
> 代码和输出保留原样。Linux perf/sysctl 等命令是课程材料，不代表本轮翻译执行了系统设置。

本部分研究性能及其背后的数据结构/算法。前面关注撮合规则和协议是否正确，现在关注热路径速度、分配量和如何测量。

第三部分从异常客户看资源，本部分从交易所内部让代码更快、更省，并用 benchmark 支撑。变更有两类：

- 保持 mli 的内部替换，客户看不到变化，旧测试不动仍通过，benchmark 改善。
- 跨模块表示变更，如字符串换整数，影响模块甚至进程边界，需要权衡正确、可读和可维护性。

回到个人工作，可用 Claude。练习 0 独立于交易所，先用 Core_bench 掌握测量；后续回到交易所。

**学习目标：** 优化前测量；理解 Time/Run、mWd/Run 和 GC；区分真实变化与噪声；掌握 list/array 等复杂度；看见内存分配成本；设计紧凑内部表示及可读外部边界。

<a id="exercise-0-benchmarking-warm-up"></a>

## 练习 0：基准测试热身

先读 [README 基准测试](../README.zh-CN.md#benchmarks)，运行 lib/order_book/bench，理解 ascii 输出列。

目标是学会把测量数字与代码对应，而非写聪明代码；后续每项优化都需测量依据。

<a id="0a-using-bench"></a>

### 0a：使用 bench

performance/src 有：

- key_value_stores.ml/mli 的 Silly_store：int→int 关联列表，故意很慢；set 删除旧键、append 到尾再读回，get 未找到还再试一次。
- jsip_exchange_perf_lib.ml：sizes、present_key、absent_key、bench_silly 和 command group。

1. 运行并对应代码：

```sh
dune exec performance/bin/main.exe -- silly -ascii -quota 1
```

Bench.Test.create 的 unit→结果函数叫 thunk，它会重复计时。concat_map sizes 让 build/get_hit/get_miss 在 10、100、1000 各测一次，make_command 生成 silly 子命令。

2. 看什么在计时区间：查询的 prebuilt 在 thunk 外只建一次，只测查找；build 放在 thunk 内，测构建。准备 fixture 和被测操作要分开。
3. 原文用带类型的 ignore 消费结果，意图避免编译器把无观察的工作优化掉。译注：一般情况下仅 ignore 并不是所有优化器下的绝对屏障；应结合工具链了解 benchmark 防优化手段。
4. 比较 quota 1/5/10，quota 越大样本多、稳定但耗时长。
5. 改 sizes 增加 10_000 或中间点；O(n²) 构建在大 n 需耐心。

思考 build/get 随 n 如何增长，并从代码解释；看 mWd/Run；几 ns 或少数 words 的差异可能是噪声，边缘结果加 quota 重测；help 可查看按名称过滤和选列。

<a id="0b-sequential-access--list-vs-dynarray"></a>

### 0b：位置访问——list 与 Dynarray

在 sequences.ml 实现两种位置容器，键是从 0 开始的索引：

- create。
- set ~key ~data：更新已有位置；key 等于长度时追加；超出范围抛异常。
- get 返回该位置或越界 None。

只允许尾部扩展，保证稠密且无洞。分别用 list 和标准库 Dynarray。

给 jsip_exchange_perf_lib 增加 sequential 子命令：按序插入 n 个、命中查询、越界查询，覆盖不同规模。运行并解释 set/get 成本。

可选 remove 指定位置并移动之后元素，分别删头删尾，先预测再测。

<a id="0c-associative-access--map-vs-hashtbl-and-the-cost-of-the-key"></a>

### 0c：关联访问——Map、Hashtbl 与键成本

associatives.ml 实现六个 key→int store：

- Map/Hashtbl × int/string/多字段 record。
- create/set/get，value 都是 int。
- int/string 键由索引生成。
- 胖 record 含整数、字符串、bool、variant，派生 compare/hash，按索引生成不同键，用来显露比较/哈希成本。

associative 子命令对 build/get_hit/get_miss 扫描规模。

问题：Map/Hashtbl 随 n 怎么变？何时超过关联列表？int 键下哈希表何时明显优于 Map？用中间点找到交叉区间。

<a id="0d-allocation--the-same-answer-computed-wastefully"></a>

### 0d：分配——相同结果，浪费不同

在 allocations.ml 实现成对算法，结果相同但分配不同：

- 复制列表：每步 acc @ [x]，与前插后最终反转。
- 找首个满足谓词：全表 filter 后取头，与 List.find。

allocation 子命令先看 mWd/Run，再看时间。解释多余分配位置、O(n)/O(n²) 差别及哪些写法容易误用。

<a id="0e-give-hashtbl_int-an-o1-random_element-optional"></a>

### 0e：给 Hashtbl_int 增加 O(1) random_element【可选】

异常 bot 要均匀随机撤一条挂单，同时不断增删。set/get/remove 已平均 O(1)，新增：

```ocaml
val random_element : t -> Random.State.t -> int option
```

均匀随机选键对应的值，空表 None，显式传 Random.State 保证测试可复现。

先保持底层结构写朴素正确版本并测量；再改变/增强表示使随机选择快。哪些辅助结构能同时支持快速增删和随机选择？用 benchmark 证明收益。

<a id="exercise-1-snapshot-side"></a>

## 练习 1：订单簿快照

这是对交易所最温和的修改。Book.t 是查询时的只读展示，snapshot 不是每单必经的撮合热路径。先运行原 benchmark：

```sh
dune exec lib/order_book/bench/bench_order_book.exe -- -ascii -quota 5
```

quota 5 可能几分钟，迭代用 1。名字与 README 对照，n 是挂单数。阅读 fixture 在 thunk 外、ignore、规模扫描的模式。

将原来平铺的 Bench.make_command 改成 Command.group，把现有测试放 existing：

```ocaml
let () =
  Command_unix.run
    (Command.group
       ~summary:"JSIP order-book benchmarks"
       [ "existing", Bench.make_command tests ])
;;
```

以后新 benchmark 家族各加子命令，避免每次重跑全部。

按 book.mli，bids/asks 应按价格汇总：每档一个 Level，总剩余量、最优价在前，和 BBO 一致。当前 snapshot_side：

```ocaml
let snapshot_side t (side : Side.t) =
  let compare =
    match side with
    | Buy -> Comparable.reverse Level.compare
    | Sell -> Level.compare
  in
  orders_on_side t side |> List.map ~f:Level.of_order |> List.sort ~compare
;;
```

问题：

1. 每订单一个 level，同价多单未聚合，违反接口。
2. 完成第一部分后，复合键 Map.data 已按价和到达时间排序，再 sort 是冗余 O(n log n)。

改成线性遍历合并同价；卖侧自然升序，买侧反转。接口不变。

**新 benchmark：** 原 fixture 每单不同价，测不出聚合。构造 n 条全 $150 的卖单，测 snapshot，放新子命令：

```ocaml
[ "existing", Bench.make_command tests
; ( "snapshot"
  , Bench.make_command (List.map sizes ~f:(fun n -> bench_snapshot ~n)) )
]
```

必要时把 sizes 提到共享作用域。比较优化前后的 Time/Run 和 mWd/Run。新增同价、不同参与者的快照 expect test，防止回归。

<a id="exercise-2-internal-symbol-as-int"></a>

## 练习 2：内部用整数表示 symbol

内部优化，mli 不变：“边界保留字符串，内部使用整数/数组”。

现有结构：

```ocaml
type t =
  { books : Order_book.t Symbol.Map.t
  ; ...
  }
```

book/submit/cancel 都 Map.find，字符串键平衡树查询 O(log n) 次字符串比较。symbols 上千后可改成一次字符串哈希查 ID，再 O(1) 数组索引。

先写纯 book 查询 benchmark，原单 symbol 测试看不出差别；不要混进 submit/cancel 撮合成本。先记录 before。

create 已获得完整 symbol 列表，逐个编号 i，同步建立 symbol→ID 和 Order_book array。symbol 集合固定，ID 一生稳定，普通固定数组足够。

可用 hash table+array，或小 registry 封装；全部留在 ml，不动 engine mli。更新每个查找路径，旧测试不改仍过。用 100、10_000 symbols 观察收益，少量时可能不明显。

<a id="exercise-3-internal-participant-as-int"></a>

## 练习 3：内部用整数表示参与者

比前两题跨更多服务器模块，但不改变网络协议。重点不是几次查找的微小速度，而是边界设计，为下一题做准备。

当前身份在 login 从名字建立；submit/cancel 由 session 注入，server 在线表和 dispatcher sessions 以名字索引，Fill 携带双方。

登录时把名字 intern 成整数，服务器内部表用 ID，外部仍名字。

三个设计点：

1. **两个类型：** Participant.t 仍是纯名字，不要为了整数拖进全局 registry。新增 private int 的 Participant_id.t，因为不跨网络，放 gateway，而非网络类型 lib/types。
2. **全服务器、只增注册表：** 名字↔ID 由所有连接共享，断线重连仍同 ID。它与只记录当前在线身份、断开会删除的 logged_in_participants 不同。参与者动态增长，选择能扩容的结构。
3. **边界解析：** 登录进入名字，内部用 ID；事件/显示等需要名字时由 registry 转回。客户端不见 ID，协议不改，不需要目录。

本练习有意停在 gateway。进一步把 ID 推入 engine orders_by_client_id 会改变引擎接口或引入 registry，留待以后。

**无需 benchmark：** 少数参与者的 int/string 差异很小，测量容易全是噪声；本题以正确性证明架构价值。

<a id="exercise-4-external-symbol-as-int"></a>

## 练习 4：网络也用整数 symbol

第二题只内部 intern，网络仍字符串；本题把 ID 推向网络及客户端，让从发送到返回都用整数。

它与第三题相反：这里会改 bin_io 摘要、缩小消息，并用目录恢复多个证券的名字。服务器不负责显示 symbol，只服务目录和校验 ID。

<a id="phase-1-ints-everywhere"></a>

### 阶段 1：处处整数

先证明不恢复名字也能完成所有功能：

- lib/types 新增 private int Symbol_id.t，因为它跨网络。
- Request/Book/Fill/Exchange_event 和查询类型改用 ID。
- 不信任客户端，拒绝格式/范围错误 ID。
- lib/types 保持纯数据、to_string 只打印整数，不注入 registry。

此时用户输入原始 ID，仍能提交、撮合、查簿、订阅；证明名字目录改善可读性，而非核心正确性。

<a id="phase-2-add-a-directory-to-recover-names"></a>

### 阶段 2：增加目录恢复名字

- 新增 symbol-directory RPC 返回 name/id 对，权威 registry 由 main 的 symbol 集构造并传入 server。
- 客户端和 monitor 连接时读一次，建双向本地镜像。
- 命令解析 name→ID，事件/簿显示 ID→name。
- Hydration（补齐名字）属于消费者：入口可把 ID 补成 {id;name} 供显示，或打印时查目录，不能让纯类型模块依赖有状态 registry。

Symbol.t 仍是外部可读名字，Symbol_id.t 是网络/服务器整数，不合并。

**Benchmark：**

- symbol-lookup 对比原 map、第二题 hash+index、本题 bounds-check+index，测 10/100/10_000。
- 可选 bin_size_t 测 Request/Book/Fill/Event 每消息节省多少字节，属于确定性 expect test，不只是时间测量。

更新 wire-shape 测试；多 symbol 输出可能按数值而非字典序。新增越界拒绝测试；客户端 BUY AAPL 必须仍能映射到正确簿、显示回 AAPL。

<a id="exercise-5-book-by-price-optional"></a>

## 练习 5：按价格组织订单簿【可选】

开放设计。完成第一部分后用平铺 (Price,Order_id) Map，找出随挂单数变慢的操作、解释原因，再设计更好结构。

保持 order_book.mli，不改客户端/网络，用旧测试作安全网：

- 跑 existing，关注 BBO/快照等“听起来便宜”的查询。
- 当前结构缺少什么而不得不全簿计算？它擅长什么，如何保留？
- 用热身各容器的性能特点选择方案。第一部分按价格分层+队列可重看。

说明快了哪些操作、到什么复杂度；代价是其他操作、内存还是复杂度；任意 ID 撤单如何继续快。有些结构持引用可 O(1) 删除，有些还得先扫描，反向索引至关重要。

先预测、再测、解释不符合预测之处。理想重构后，之前快照聚合或最优档数量的“每次计算”可能变成结构自然提供，表明结构匹配问题。

可沿用或新增 benchmarks。

<a id="exercise-6-workload-and-profile-stretch"></a>

## 练习 6：工作负载与性能剖析【拓展】

微基准在热缓存、无竞争情况下隔离操作，适合比较容器，但不能说明满负载时 CPU 去哪里。

Linux perf 采样剖析定期打断程序，记录调用栈并汇总；约 30% 样本落在 find_match，意味着约 30% CPU 消耗在那里。

构造比第二部分场景更密集、可复现的负载，主要交付是时间花费的解释。

<a id="the-workload-generator"></a>

### 工作负载生成器

第二部分 bots 按 tick 节流，服务器多数时间空闲，直接 profile 它们可能只看到等待。

新模块由一个 seed 的 Splittable_random.State 派生全部随机，生成 submit/cancel 流。Config 至少能调：

- symbols/参与者数量。
- 取消/提交比例。
- 可成交/挂单比例。
- IOC/Day 比例。
- 订单大小。
- 价格漂移及挂单离最优价的距离。

设计 balanced、churn（取消多）、book-heavy（挂单堆积）等 preset。直接调用引擎，不走 RPC。

注意：

1. 不复用客户 ID，已使用 ID 保留。
2. 簿须达到稳态，不可无限积累；周期打印深度验证。
3. 价格不能跑飞，否则无法成交的 balanced 实际变 book-heavy；计数实际 Fill，不只信配置。
4. 原文使用 Splittable_random.State.of_int，并允许分拆 state，只要都源于根 seed。具体 API 以库版本为准。
5. 生成器自己不要过量分配，否则测到的是它而非引擎。

<a id="the-replay-driver"></a>

### 回放驱动器

在 performance 的 Command.group 增加 replay，Dune 加 types/order_book 依赖。建引擎，同步执行 N 次 submit/cancel，输入 seed/Config，不用 Async/RPC/Pipe。

先定义输出：总墙钟时间、orders/sec、p50/p99/p99.9/max 延迟、accept/fill/cancel/reject 数量、GC 指标。用清晰 ASCII 表或直方图，直方图自己也写 expect test；可探索 [Owl](https://ocaml.xyz/)。

把吞吐与 existing 的 submit_ioc_cross(n=100) 时间倒数比较；通常不一样，思考 fixture 和生成器的实际工作，而非只看数字。

<a id="profile-it-with-perf"></a>

### 用 perf 剖析

Ubuntu 默认限制 perf，原文给出 sysctl 设置（重启后可能重设）：

```sh
sudo sysctl kernel.perf_event_paranoid=1   # allow profiling your own processes
sudo sysctl kernel.kptr_restrict=0         # allow resolving kernel symbols
```

先对无关程序做 smoke test：

```sh
perf record -F 997 --call-graph=dwarf -- timeout 5 sha256sum /dev/zero
perf report --stdio --no-children | head -25
```

record 对 sha256sum 五秒、997Hz 采样保存 perf.data，report 的 Overhead 是该函数样本比例。

若只有地址而无函数名，常因为 Ubuntu 剥离了 sha256sum 符号表。OCaml binary 保留符号，Dune 的 -g 支撑 DWARF 回溯：

```sh
dune build --profile release
perf record -F 997 --call-graph=dwarf -- \
  _build/default/performance/bin/main.exe replay -preset balanced -num-actions 5000000
perf report --stdio --no-children | head -40
```

- 直接 profile _build 中 binary；perf record dune exec 会把 Dune 进程树也测进去。
- OCaml 缺省不维护 frame pointer，需 --call-graph=dwarf；文件可能很大，采样控制约一分钟。

阅读：

- 顶部行表明 CPU 真正去处。
- camlOrder_book__find_match_1234 对应源函数，camlMap__ 对应底层树。
- minor/major collection、caml_alloc*、memmove 等运行时工作合计是 GC 税，相当于分配量最终变成时间。
- 交互 perf report 展开调用链，查谁调用热点。
- 共享机器有噪声，同配置至少两次比较。

**交付：** 每 preset 手工做组件预算表，不为此另外写复杂代码。把函数归到撮合、簿修改、BBO 记账、事件构造、生成器、GC、其他运行时，合计解释至少约 85% 样本。相同 camlMap__bal 在 Order_book.add 下是簿修改，在生成器下是生成器开销；不确定就展开 caller，不能猜。

<a id="the-long-run"></a>

### 长时间运行

数百万操作，每约百万打印 Gc.stat，至少 live_words。簿稳态后 live heap 本应平台化；原文提醒它可能仍增长，需要定位。

细看并实测：哪里分配、为什么持有、持有多久？

<details>
<summary>提示</summary>

提交和取消之后，引擎究竟永久保存了什么，生命周期多长？

</details>

不能只看代码猜，要埋点记录函数调用及 live_words 变化。

<a id="profile-the-real-server-optional"></a>

### 剖析真实服务器【可选】

纯 replay 为了隔离引擎去掉网络；真实 server 还有反序列化、分发和 Async 调度。用登录后紧循环提交、不断 drain session 的 firehose 客户，按 PID profile server：

```sh
perf record -F 997 --call-graph=dwarf -p "$(pgrep -f app/server)" -- sleep 30
```

这不像 replay 确定，双 vCPU 机器又受客户端竞争影响，以预算百分比而非吞吐作为重点。

问题：

- submit 占服务器 CPU 多少，剩下去哪里？
- 零订阅与 monitor+多个行情订阅对比，新增订阅的成本谁承担？
- symbol interning 的收益在这里看得到吗？看不到时，结合两类实际数字解释微优化何时仍值得做。

**AI 提示：** Claude 可帮助 perf 命令、解析符号、生成器支架，但容易误判负载是否代表真实业务、把样本归错、将测量噪声当胜利。预算表和长期内存结论应由你判断。
