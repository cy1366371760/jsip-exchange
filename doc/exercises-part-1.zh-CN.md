<a id="jsip-exercises---part-1"></a>

# JSIP 练习：第一部分

> 中文对照：[英文原文](exercises-part-1.md)。代码、标识符和测试输出保留原样。本文描述课程练习目标，不代表当前仓库已实现这些功能。
> 译注：本项目现已支持 `000001.SZ` 形式的 A 股代码；练习 3 的“只允许大写字母和数字”若直接照做，会拒绝其中的点号，需要结合现有行情边界重新考虑。

本部分先带你熟悉交易所代码，再完成第一批实质性修改：实现价格比较原语、修复价格时间优先撮合、增加订单有效方式和事件驱动处理，并将一部分 LLM 生成的命令解析代码重构成更符合 OCaml 惯例的写法。练习由小到大，完成后会接触系统的每一层。

**第一部分的学习目标：**

- 阅读 `.mli` 理解公开 API，并据此探索陌生代码库。
- 编写 expect tests，用 `dune promote` 迭代预期输出。
- 使用 Core 的高阶列表函数：`filter/fold/reduce/sort`。
- 扩展普通变体类型，利用模式匹配穷尽性警告找到需要更新的位置。
- 识别并重构 LLM 常见问题：用字符串分派、逻辑分散且无人统一负责、与类型定义不同步的硬编码列表。
- 理解价格时间优先、订单有效方式、收盘处理和防自成交等规则，并能解释规则存在的原因。

---

<a id="exercise-1-implement-priceis_more_aggressive-and-priceis_marketable"></a>

## 练习 1：实现 `Price.is_more_aggressive` 和 `Price.is_marketable`

实现两个函数。前者判断某个价格对指定买卖方向是否更积极：买方愿意付得越高越积极，卖方愿意收得越低越积极。后者判断指定方向的订单能否与某个已有挂单价格成交。

随后将 `Order_book` 内部的 `best_price` 和 `Order_book.find_match` 改为调用这两个函数，替换散落的按方向比较。注意 `best_price` 是 `order_book.ml` 的私有辅助函数，没有在 `.mli` 中公开，它支撑 `best_bid_offer`。找最优价格可以用一次 `List.reduce`，不必另写模式匹配。[^reduce]

[^reduce]:
    `List.reduce` 用你提供的函数把整个列表合并为一个值；空列表返回 `None`，否则返回 `Some result`。例如 `List.reduce [3; 1; 4; 1; 5] ~f:Int.max` 得到 `Some 5`。这里对价格列表做 reduce，每次用 `Price.is_more_aggressive` 保留两个价格中更积极的那个。

与某个类型相关、可复用的逻辑应放进该类型所属模块。否则类似价格比较会散落各处，难以改进和维护。

**提示：** 阅读 `price.mli` 中两个函数的说明。

**测试：** 在 `lib/types/test/test_price.ml` 覆盖买卖两侧及价格相等的边界情况。

课程稍后会讲测试；现在可以参考 [Real World OCaml：Expect Tests](https://dev.realworldocaml.org/testing.html#expect-tests)。

---

<a id="exercise-2-fix-price-time-priority-matching"></a>

## 练习 2：修复价格时间优先撮合

当前订单簿用未排序列表保存订单，`find_match` 返回碰到的第一条可成交挂单，而非价格最优的那条，买方因此可能多付钱。“price priority is broken” 测试演示了这个错误。

<!-- TODO: link to test file lib/order_book/test/test_matching_engine.ml#217:233 -->

**要做的事情：**

1. 扫描对手侧挂单，返回最积极的价格：买单对应最低卖价，卖单对应最高买价。同价时选最早加入的订单。
2. 修改 `snapshot_side`，使展示顺序与实际撮合顺序一致：买价由高到低，卖价由低到高，同价按到达时间。客户查询到的订单簿应反映撮合顺序，而非插入顺序。
3. 更新受影响的 expect 输出，包括 `test_matching_engine.ml` 的价格优先测试和 `test_order_book.ml` 的快照测试。

**提示：**

- 可以先过滤可成交挂单，再用一次 fold 和 `Price.is_more_aggressive` 找最优。不必排序整个列表。
- 较小的 `Order_id` 表示更早到达，因为 ID 生成器是顺序递增的。
- 当前快照先把订单转成 `Level.t = { price; size }`，再用 `Level.compare` 排序，但此时已经丢失到达时间。应先按价格和 `Order_id.compare` 排序底层 `Order.t list`，再转成 level。
- 成交顺序和快照顺序变化会改变现有测试的输出；这是预期修正，因为旧输出本来就错了。

---

<a id="_exercise-3-add-symbol-validation_-optional"></a>

## 练习 3：增加证券代码校验【可选】

`Symbol.of_string` 当前接受任何非空字符串。增加校验，要求只包含大写字母和数字。

**设计决定：** `of_string "aapl"` 应报错，还是自动转成大写？两种都可以，但要在注释中解释选择。

**提示：**

- Core 的 `String.for_all` 配合 `Char.is_alphanum` 是逐字符验证的惯用写法。
- 客户端 `app/client/bin/main.ml` 在处理 `BOOK/SUBSCRIBE` 时已经先转大写；处理 `BUY/SELL` 的 `Protocol.parse_command` 则直接传入。如果模块自动转大写，调用者不必重复做；如果模块拒绝大小写混用，就应让这两条解析路径一致。

**测试：** 在 `test_symbol.ml` 覆盖合法代码、特殊字符、空字符串和选定的小写处理规则。

---

<a id="_exercise-4-participant-view-fills_-optional"></a>

## 练习 4：从参与者视角显示成交【可选】

给 `Fill` 模块增加 `to_participant_view : t -> Participant.t -> string option`。

从特定参与者角度格式化成交。不要只显示交易所视角的“aggressor=Alice BUY resting=Bob”，而应显示“你以 $150.00 买入了 100 股 AAPL”或对应的卖出消息。如果成交与该参与者无关，返回 `None`。

这应成为网关发给个人客户的展示形式，而不是原始成交记录。

**提示：** 挂单方方向是 `Side.flip fill.aggressor_side`，没有单独存进 record。主动方买入，挂单方就是卖出。

在 `test_fill.ml` 增加 expect test。

目前该函数还没有用于客户端显示：网关尚未给个人发送成交消息，服务器仍用 `Protocol.format_event`。先用单元测试证明函数行为；第二部分练习 1c 接通 session feed 时再接入。

---

<a id="_exercise-5-end-of-day-processing_-optional"></a>

## 练习 5：收盘处理【可选】

增加函数，取消所有仍挂在簿中的 Day 订单，并发出原因为 `End_of_day` 的 `Order_cancel`。

1. 给撮合引擎增加 `end_of_day : t -> Exchange_event.t list`。
2. 遍历全部订单簿，收集 Day 挂单、移除它们并生成取消事件。
3. 测试订单确实移除，返回事件内容正确。

**提示：**

- `orders_on_side` 返回数据快照，所以可以在遍历时删除原簿中的订单。若返回的是实时可变视图，这样做就不安全。
- IOC 本不应挂在簿中；仍应防御性处理：以 `End_of_day` 取消，同时警告系统可能有 bug。
- 测试应包括多个 symbol 和部分成交订单，确认报告的是正确剩余数量。

---

<a id="_exercise-6-add-good-till-cancel-orders_-optional"></a>

## 练习 6：增加 Good-till-Cancel 订单【可选】

给 `Time_in_force.t` 增加 `Good_till_cancel`。GTC 像 Day 一样可以挂单，但收盘不会自动取消。

1. 增加变体，更新 `rests_on_book` 为 `true`。
2. 收盘处理跳过 GTC。
3. 决定重启时如何处理 GTC；暂时丢失可以接受，持久化是以后练习。
4. 在 `protocol.ml` 支持字符串 `GTC`，并同步更新客户端 `main.ml` 启动帮助。
5. 补充测试，尤其是收盘行为。
6. 手工用客户端提交一个 GTC 订单。

**提示：** GTC 是最简单的新有效方式：撮合行为与 Day 完全相同，区别只有收盘处理。

---

<a id="_exercise-7-add-fill-or-kill-orders_-optional"></a>

## 练习 7：增加 Fill-or-Kill 订单【可选】

给 `Time_in_force.t` 增加 `Fill_or_kill`，给 `Cancel_reason.t` 增加 `Fill_or_kill_not_fully_fillable`。FOK 的 `rests_on_book` 应为 `false`。

在执行 FOK 成交之前，检查对手侧可成交价格的总剩余数量是否至少等于订单数量。不足就整单取消，不产生任何成交；足够才按正常流程撮合。

**提示：**

- 遍历对手侧、累加可成交挂单的剩余数量，这是 FOK 区别于 IOC 的预检。
- 预检必须发生在任何状态修改之前，否则无法完整成交时已经改动了其他订单。
- 本练习的 FOK 失败发出 `Order_accept` 后跟 `Order_cancel`，不是 `Order_reject`：订单本身有效并已分配 ID，只是无法全部成交。后者用于未知 symbol 等无效请求。
- 取消后检查订单簿没有变化。
- 协议解析、帮助和测试也要支持 `FOK`。

**测试：** 可以完全成交、不足以完全成交、恰好完全成交三种情况。

---

<a id="exercise-8-centralize-command-parsing"></a>

## 练习 8：集中管理命令解析

目前命令处理分散在两个地方：

1. `Protocol.parse_command` 用首个字符串判断 BUY/SELL，并硬编码 `IOC/DAY`。新增有效方式时，编译器无法提醒你这些字符串也要更新。
2. 客户端 `main.ml` 用 `String.is_prefix/String.chop_prefix` 提前识别 BOOK/SUBSCRIBE，其余再交给 Protocol。帮助中的有效方式列表也是硬编码。

如果再加 CANCEL，客户端 if/else 会迅速变得难维护。这类“当前能跑，但责任分散、用字符串模拟类型”的结构是 LLM 常见产物；这段代码确实由 Claude Code 生成，课程特意保留来让你学习识别问题。

本练习要用 OCaml 类型集中承担全部命令解析和分派。

<a id="8a-define-the-command-type-and-verb"></a>

### 8a：定义命令类型和动词

在 `lib/gateway/src` 新建 `exchange_command.ml/.mli`，先定义命令首词类型：

```ocaml
type verb = Buy | Sell | Book | Subscribe
```

为它派生大小写不敏感的 `to_string/of_string`。参考 `Side.t` 的 `[@@deriving string ~case_insensitive]`，解析时直接调用 `Verb.of_string`。

然后定义已解析命令；每个构造子只携带该命令需要的数据：

```ocaml
type t =
  | Submit of Order.Request.t
  | Book of Symbol.t
  | Subscribe of Symbol.t
```

没有 `Unknown` 构造子；不能识别的命令应返回结果中的 `Error`：

```ocaml
val parse : ?default_participant:Participant.t -> string -> t Or_error.t
```

`parse` 的流程：

1. 按空格切分，取首词。
2. 解析为 `Verb.t`，失败返回 Error。
3. 按动词匹配剩余参数：Buy/Sell 解析 symbol、数量、价格、有效方式、参与者；Book/Subscribe 解析必填 symbol。

把订单解析逻辑从 Protocol 移过来，不是再包一层调用 Protocol。

可选 `default_participant` 替代原来的 `parse_command_with_default_participant`：未写 `as <name>` 时使用默认参与者；两者都无则使用 `anonymous`。

有效方式同样不要硬编码，使用已有派生的大小写不敏感 `Time_in_force.of_string`。错误消息和帮助中的有效方式列表也不要手写。通过 `[@@deriving enumerate]` 提供的 `all : t list`，配合 `List.map/String.concat` 增加 `all_str : string`，这样新增构造子后会自动出现。

更新 `jsip_gateway.ml/.mli` 导出新模块。

**提示：**

- 目标是 Exchange_command 统一拥有所有命令解析。
- 重构后 Protocol 只剩 `format_event/format_events`；可以重新考虑名字是否还恰当。
- 价格后的第一个额外词可能是 `as`，而非有效方式。现有代码在该情况下默认 Day，迁移时别丢掉。

<a id="8b-use-the-command-type-in-the-client"></a>

### 8b：客户端使用命令类型

将客户端的字符串前缀 if/else 和旧解析调用替换成一次 `Exchange_command.parse`，然后匹配结果。

各分支保持当前行为，只改变结构。连接后的帮助列表改用 `Time_in_force.all_str`。

**提示：** Error 分支打印错误后继续循环。

<a id="8c-update-tests"></a>

### 8c：更新测试

将 `test_protocol.ml` 中的命令解析测试移到 `test_exchange_command.ml`，调用新 parse。

新增：

- BOOK 携带 symbol。
- SUBSCRIBE 大小写不敏感。
- 默认参与者覆盖行为，以及明确写出的 `as` 不被覆盖。

---

<a id="_exercise-9-self-trade-prevention_-optional"></a>

## 练习 9：防止自成交【可选】

同一参与者的主动订单不能与自己已有挂单成交，否则会制造误导性的交易活动。

撮合引擎应取消可能自成交的主动订单，即对手订单参与者与自己相同的情况。真实交易所除了取消，还可能处罚提交这类订单的参与者。

---

<a id="exercise-10-improve-the-order-book-data-structure"></a>

## 练习 10：改进订单簿数据结构

将普通列表换成维护价格时间顺序的结构。现有 `find_match/remove` 是 O(n)，最优价格也不能高效取得。

**候选：**

- 每侧一个以 `(Price.t, Order_id.t)` 为键的 Map，基本操作 O(log n)，可以用 Core.Map。
- 按价格分层，每层一个订单队列，更接近实际订单簿：Map 从价格映射到队列。

**约束：** `order_book.mli` 不变，这是内部改进。

**提示：**

- 复合键比较可按价格、再按到达顺序自然排序。
- 买侧最优是最高价格，对应 `Map.max_elt`；卖侧对应 `Map.min_elt`。
- 删除要有订单 ID→存储位置的反向索引，否则按 ID 删除仍需要全表扫描。
- Map 自然升序；展示买侧要反转成最优价格在前。原文这一条末尾的 “Better yet,” 未写完。

**测试：** 现有测试应全部保持通过。

**拓展：** 对上千条订单做性能剖析，比较 list 与 map。原文链接 `overview.md#benchmarks` 在当前目录没有对应文件，可参考 [README 的基准测试](../README.zh-CN.md#benchmarks)。

---

<a id="stretch-per-participant-pl-tracking"></a>

## 拓展：按参与者跟踪 P&L

如果提前完成第一部分，编写模块根据成交追踪每个参与者的累计损益。以后实现策略时，就能问“这个策略表现如何”。

用参考价格做盯市；暂时可以用每个 symbol 的最新成交价：

- 原文将已实现 P&L 描述为平仓相关的现金收支：买入使现金减少 `size * price`，卖出使其增加。
- 未实现 P&L 描述为 `number_of_shares * (reference_price - average_entry_price)`；成交会改变数量及平均成本。
- 总损益为已实现加未实现。

> 译注：原文这里混用了“交易现金流”和“已实现损益”。买入产生负现金流不等于已实现亏损；真正实现时必须明确成本基础和平仓规则，避免把本金和损益混为一谈。这里保留课程描述用于对照，不将其当作已验证的金融计算公式。

**要实现的内容：**

1. 新建 `lib/pnl/src/pnl.{ml,mli}`，按参与者和 symbol 跟踪库存、累计成本基础和已实现现金。公开 `apply_fill : t -> Fill.t -> t`、用于更新参考价的 `apply_trade_report : t -> Trade_report.t -> t`，以及返回逐 symbol 明细和总计的 `summary : t -> Participant.t -> ...`。类型名是否存在要以实际代码为准。
2. 几个 expect tests：手工构造可核算的成交和最终公开成交记录，将 summary 与预先算好的数字比较。
