<a id="jsip-exercises---part-2"></a>

# JSIP 练习：第二部分

> 对照：[英文原文](exercises-part-2.md)。本章是课程任务，不是当前功能清单。当前登录、session feed、取消 RPC 和动态 bots 有多处未实现；读到“已经完成”时，应理解为已完成前面练习后的状态。
> 译注：本章模拟策略仅用于理解教学交易所，不是 A 股实盘规则，也不代表当前 Tushare 回放已经接入这些 bots。

本部分补齐撮合引擎的撤单功能，随后构建自动交易者及组合它们的命名场景。完成后应有一个持续产生订单、成交和行情事件的场景，可在 monitor 观察，并至少加入一个自行设计的 bot。

术语：

- best bid 是簿中的最高买价；best ask/offer 是最低卖价。
- BBO 是这两个最优报价的组合。
- resting order 是簿中等待的挂单；marketable 表示价格能与对手挂单成交。
- quote 是参与者提供的价格和数量。挂买价就是提交买侧挂单；re-quote 是取消旧报价再挂新报价。
- ladder 是同一参与者同侧多个价格的阶梯挂单，如 9.99、9.98、9.97、9.96、9.95 的五档买单。
- trade event 是 `Exchange_event.Trade_report`，公开价格和数量，不包含双方身份。

**学习目标：**

- 完成跨类型、引擎、RPC、文本协议及测试的横向功能变更，体验 monorepo 中多库/应用的协作。
- 实现跨事件保存状态的策略，理解它与其他参与者的相互作用。
- 设计 bot 公共接口并迁移已有实现，权衡框架与策略各自负责什么。
- 用 monitor 观察、调试和调整系统。

[^rpc]:
    RPC（远程过程调用）让一个进程像调用本地函数一样调用另一个进程的函数。底层通过 socket 交换消息。这里用 Async.Rpc：Rpc.Rpc.t 是一次查询/响应，Rpc.Pipe_rpc.t 是持续发送多条消息的流。

---

<a id="exercise-1-login-sessions-client-order-ids-and-cancellation"></a>

## 练习 1：登录、session、客户端订单编号和撤单

涉及基础类型、撮合、网关和测试，包含四项相互关联的功能：

- 登录：连接时确立身份，而非每条消息声明身份。
- Session：每个连接一条出站事件通道，将事件推给正确参与者。
- 客户端订单 ID：客户无需等待服务器响应，就能引用自己的订单。
- 撤单：包含对应 RPC 和文本命令。

每块都不大，组合后更接近真实的异步推送系统。

<a id="background-why-login"></a>

### 背景：为什么需要登录？

当前默认身份是 anonymous，也可在文本命令用 `as <name>`。撤单需要知道是谁请求取消，逐条信任客户自报身份不合适。

真实交易所连接时认证一次，后续消息关联该身份。字段更少，也避免冒充其他参与者。

<a id="background-why-a-session-abstraction"></a>

### 背景：为什么需要 session 抽象？

挂单可能在提交成功数分钟后被别人击中；这笔成交由别人的 submit 触发，原挂单人的 RPC 早已返回 Ok，无法靠同步响应通知。

登录时创建 Session.t，包装该连接的出站 Exchange_event Pipe。Pipe 有 reader 和 writer，像 `int list` 一样由元素类型参数化；在流式 RPC 中两端通常由不同进程持有，元素通过网络传输。

引擎产生涉及某参与者的 Order_accept/Fill/Order_cancel/Order_reject 时，Dispatcher 找 session 并写入 pipe。客户端通过新增 session_feed_rpc 持续接收。已有的引擎/队列机制可复用，要补的是握手、注册和打印→pipe 的连接。

<a id="background-why-client-order-ids"></a>

### 背景：为什么需要客户端订单 ID？

服务器现在接受订单后才分配 ID；响应延迟或丢失时，客户不知道怎样引用或撤销。客户先自选 ID 就能跟踪订单。

内部 Order_id.Generator 仍存在，用于全局价格时间顺序；但只留在引擎内部。面向客户的提交、取消和事件改用客户端编号。

<a id="the-starting-state"></a>

### 起始状态

先读已有代码：

- session.ml/mli：Participant 和出站事件 Pipe，提供 create/participant/reader/push/close，初始没有调用者创建它。
- dispatcher.ml/mli：管理行情订阅和事件路由。原文说有 on_session_event callback；当前 checkout 的对应占位是 push_to_session 打印。
- exchange_server.ml：一个长期 Async 任务按顺序读请求队列、执行 submit、再 dispatch。Async 是协作式并发 I/O，不是每个请求一个线程。submit handler 入队后返回 Ok；后台 loop 保证处理顺序。所有这些仍可在一个 OS 进程内运行。

初始连接没有认证，网关信任 Order.Request.participant；本练习会修正。

<a id="1a-session-registry-on-the-dispatcher"></a>

### 1a：Dispatcher 的 session 注册表

扩展 Dispatcher，增加 `Session.t Participant.Table.t` 和：

- `clean_up_session : t -> Session.t -> unit Deferred.t`。
- `set_up_session : t -> Participant.t -> unit Deferred.t`：已有 session 时先清理再创建。

Deferred 是将来才完成的值，类似 future/promise。清理要关闭 Pipe 并等待，故返回 Deferred；let%bind 表示等待完成再继续。

把 push_to_session 改成查询注册表并调用 Session.push；不存在 session 就不推送。

> 译注：原文 1a 描述替换旧 session，1b 则要求登录同名冲突时返回错误。实现前需要统一重连/重复登录政策，不能让两段规定彼此抵消。

<a id="1b-login-rpc-and-connection-state"></a>

### 1b：登录 RPC 与连接状态

在 rpc_protocol.ml/mli 增加 login_rpc：输入名字字符串，返回 Participant.t Or_error.t。

Handler 要校验非空/非纯空白，创建 session，注册时检查冲突，并存入连接状态。

这不是完整认证：只要当前没被占用，客户就可自称 Alice。生产系统需要 TLS 证书、Kerberos 或另行发放 API key；末尾拓展练习会讨论。

Async RPC 给每个连接一个状态，并作为首参数传给每个 handler。当前初始状态是 unit，需改为可变 record 保存 session：

```ocaml
module Connection_state = struct
  type t = { mutable session : Session.t option }

  let participant t = Option.map t.session ~f:Session.participant
end
```

连接关闭时从 dispatcher 注销并关闭 session pipe。可在 initial_connection_state 内用 Rpc.Connection.close_finished 启动清理任务。

submit handler 改成：

1. 无 session 返回 not logged in。
2. 用 session 身份覆盖 request.participant，不能代别人下单。
3. 按原方式入队。

更新场景运行器、server 的预置做市商/往返交易模式及其他调用者，先登录后提交。给 test_rpc_shapes.ml 增加 login_rpc 的结构测试。

<a id="1c-session-feed-rpc"></a>

### 1c：Session feed RPC

增加 `session_feed_rpc : (unit, Exchange_event.t, Error.t) Rpc.Pipe_rpc.t`。无登录失败，否则返回该 session 的 reader。客户登录后订阅一次，持续读。

此通道负责该参与者的接受、取消、拒绝及成交事件。交互客户端应订阅并打印；Fill 用第一部分的 to_participant_view 显示“你买入/卖出”。

更新 e2e_helpers.ml：connect_as 不再忽略 participant，而是在同一连接登录、订阅 feed、启动后台带参与者前缀的打印：

```ocaml
let%bind (_ : Participant.t) = login client.conn participant in
let%bind session_feed, _metadata =
  Rpc.Pipe_rpc.dispatch_exn Rpc_protocol.session_feed_rpc client.conn ()
in
don't_wait_for
  (Pipe.iter_without_pushback session_feed ~f:(fun event ->
     let e = Protocol.format_event event in
     print_endline [%string "[%{participant#Participant}] %{e}"]));
```

这样 end-to-end expect 测试能看见个人事件，多客户输出也清晰。更新 mli 中 connect_as 的说明，删掉“将来才接通”的备注。补 session_feed_rpc 的 wire-shape 测试。

<a id="1d-client-order-id-in-the-request"></a>

### 1d：请求携带客户端订单 ID

新增 Client_order_id 模块，给 Order.Request.t 增加 `client_order_id : Client_order_id.t`。采用类似 Order_id/Size 的 int 封装：

```ocaml
type t = int [@@deriving sexp, bin_io, compare, equal, hash]
```

文本协议：

```
BUY <client_id> <symbol> <size> <price> [DAY|IOC]
```

例如 BUY 42 AAPL 100 150.00 表示客户端 ID 为 42；参与者由登录决定。

事件应携带用于对应请求的客户端 ID：

- Order_accept 已含 request，读取其 client_order_id，不重复加字段。
- Order_cancel 新增 client_order_id。
- Fill 新增 aggressor_client_order_id 和 resting_client_order_id，两方都可能是当前 bot。

这会改动 RPC 二进制类型布局；submit-order 摘要会变。重新测试，审阅差异，再 promote。

<a id="1e-duplicate-detection"></a>

### 1e：检测重复 ID

同一参与者不能重复提交已使用的客户端 ID。增加索引，每次提交检查；重复则发 Order_reject 并推给 session。

订单成交/取消后是否释放 ID 槽位？保留可避免误重用，释放允许回收。原文倾向保留，以利调试和审计。

<a id="1f-matching-engine-cancel"></a>

### 1f：引擎撤单

按 `(participant, client_order_id)` 查询内部订单：

1. 找到订单。
2. 从簿移除，发原因为 Participant_requested 的 Order_cancel。
3. 若最优档受影响，发 BBO 更新。
4. 不存在（包括已经成交或取消）时发新增 Cancel_reject：

```ocaml
| Cancel_reject of
    { participant : Participant.t
    ; client_order_id : Client_order_id.t
    ; reason : string
    }
```

**提示：** 不需要给 Order.t 加 is_cancelled。完全成交和撤单都使它离开簿；区别由 Fill/Order_cancel 事件表达。

<a id="1g-cancel-rpc-and-cancel-command"></a>

### 1g：取消 RPC 与 CANCEL 命令

增加 `cancel_order_rpc : (Client_order_id.t, unit Or_error.t) Rpc.Rpc.t`，和 submit 一样入队后返回。最终取消成功/失败走 session feed。文本命令为 `CANCEL <client_order_id>`，补 wire-shape 测试。

> 译注：本节原文用 Order_reject 描述 not found，而 1f 定义的是 Cancel_reject。应以明确设计的取消失败事件统一实现。

<a id="tests"></a>

### 测试

覆盖：

- 按客户端 ID 撤单，挂单者收到取消。
- 重复 ID 被拒绝。
- 取消已成交或不存在订单，收到 not found。
- 撤单后 BBO 更新。
- 别人的主动单击中自己的挂单时，挂单者仍收到 Fill——这是 session 的核心动机。
- 未登录不能提交或取消。
- 两连接同名登录，第二个失败。

保持 wire-shape 测试同步：新增字段、RPC、Cancel_reject 会改变摘要。每次协议修改后核对变化确实对应本次变更，再 promote。新 RPC 可复制已有测试，但要区分普通 RPC 和 pipe RPC。

**提示：** 内部 ID 仍可用于簿中 Map 的价格时间键，但不暴露给客户；登录后提交不再需要 as 子句。

---

<a id="exercise-2-make-the-market-maker-dynamic"></a>

## 练习 2：让做市商动态响应

扩展 app/market_maker，利用撤单响应自身成交。

<a id="background-static-vs-dynamic-market-makers"></a>

### 背景：静态与动态做市商

做市商持续提供某证券买卖价，买价略低于其 fair value，卖价略高，价差形成潜在收益。双向成交可以买低卖高，同时给其他人提供随时交易的流动性。

初始做市商是静态的：seed_book 放好买卖阶梯就结束，既不看提交结果，也不跟踪之后成交。如果一侧持续被交易，会积累危险库存。

- Long 多头：买得比卖得多，净股数为正。
- Short 空头：卖得比买得多，净股数为负。
- Inventory/position：净股数，买入增、卖出减；零表示不承受该标的净价格敞口。

例如市场不断从做市商买入，它持续卖出、越来越空，而价格上涨，亏损可能超过价差收入。动态做市商按库存调整报价，这叫 quote skew（报价偏移）。

<a id="what-youre-working-with"></a>

### 当前已有内容

先读 market_maker.ml/mli，初始 API：

```ocaml
val seed_book : Config.t -> Rpc.Connection.t -> unit Deferred.t
```

它通过 RPC 放阶梯后返回，没有状态和事件循环。要动态化需要：

1. 订阅练习 1 的 session feed，接收涉及自己的 Fill 并更新库存；不要用面向运营监控的 audit feed。
2. 保存仍在簿中的客户端订单 ID，以便撤旧报价。
3. 使用 cancel RPC。

自然新增 API：

```ocaml
val run : Config.t -> Rpc.Connection.t -> unit Deferred.t
```

内部放初始阶梯、订阅 feed、处理成交后撤旧挂新，返回不会完成的 Deferred。

<a id="2a-track-inventory-and-outstanding-orders"></a>

### 2a：跟踪库存和未完成订单

长期做市商维护：

- 按 symbol 的净库存。成交中无论是主动方还是挂单方，都要正确判断买卖方向。
- 当前在簿客户端 ID 集合。接受事件从 request.client_order_id 记录；取消时移除；完全成交时根据自己处于主动/挂单哪侧匹配对应 ID 并移除。

**测试：** 给事件处理器输入一小段事件，断言库存和未完成订单状态，别只目测日志。

<a id="2b-cancel-and-re-quote-on-every-fill"></a>

### 2b：每次成交后撤单并重新报价

库存记账正确后，每次 Fill 撤掉该方向的全部挂单，或为简单起见两侧都撤，再挂新阶梯。

原文建议忽略“order not found”的撤单失败：订单可能已经被引擎成交或删除。

**测试：** mock 连接记录 submit/cancel，注入对自己的挂单成交。预期顺序是初始 submits→旧 IDs 的 cancels→同价格新 submits。此阶段尚未引入 skew，所以价格不变。

<a id="2c-skew-the-quote-ladder-by-inventory"></a>

### 2c：按库存偏移报价阶梯

最简单公式：

```
skewed_fair = fair_value - (inventory * skew_cents_per_share)
```

正库存降低 fair，买卖报价一起下降，意图是少买、多卖，让库存回到零。

> 译注：原文此处把与降低 bid/ask 交易的买卖方称呼写反。降低 bid 使卖方更不愿向做市商卖，降低 ask 使买方更愿从做市商买；因此有助降低多头库存。

给配置增加：

```ocaml
{ ...
; inventory_skew_cents_per_share : int
; ...
}
```

太小抑制不了库存，太大则报价偏离合理范围、无人交易。在场景中调参。

**测试：** Fill 后下一组报价体现新偏移；交替买卖使报价围绕 fair 对称移动。

**拓展：** 多证券按相关风险偏移：配置 [-1,1] 相关系数矩阵，X 的有效库存为 `pos_X + sum_over_Y(corr_XY * pos_Y)`。一笔相关证券成交可能要重报多个 symbol。矩阵的合理估计另有研究难度，先用固定配置即可。

---

<a id="exercise-3-port-the-market-maker-to-the-bot-framework"></a>

## 练习 3：把做市商迁移到 bot 框架

多个不同 bots 都需要 RPC、事件订阅、周期动作和场景组装，共同机制已在 Bot_runtime 和 Scenario_runner。

- tick 是按 tick_interval 的周期 callback，用于定期刷新报价、随机决定是否操作。
- fundamental 是 oracle 维护的模拟真实价值，可渐变或受新闻冲击。它不是 BBO。真实参与者有不同且私有的估值，教学模拟让 bots 共享 oracle，便于观察动态。

先读 bot_runtime.mli 的 Config/on_start/on_tick/on_event 和 Context；再读 scenario_config/bot_spec 的组装方式及 runner 的连接过程。

迁移前补基础设施：

- Context.cancel 改为 Client_order_id.t；submit 直接传带 client_order_id 的 Request，编号由 bot 自选。
- start_bot 先 login，再 session feed；将 session 和行情事件都传给 feed_event，可用 interleave 或两条 Pipe.iter。把取消 stub 接上真实 cancel_order_rpc。

**要实现：**

1. 在 app/market_maker/src 新增 Market_maker_bot，符合 Bot_runtime.Bot。身份、RNG、oracle、submit/cancel 改从 Context 读取，不重复放 Config。
2. 初始阶梯放 on_start，它应只调用一次且先于 tick/事件；周期刷新放 on_tick，也可为空；库存、撤单、skew 重报放 on_event。
3. 删除旧 seed_book 和动态 run，由 bot 统一替代；同步更新 server 的旧 seed flag。

**提示：** per-symbol 状态用 Symbol.Table；客户端 ID 的作用域是参与者，因此若一个参与者交易多个 symbols，仅用“每 symbol 从同一个初值计数”会冲突，须保证该参与者全局唯一。

**测试：** 用 For_testing.context_of 和 mock submit/cancel 记录闭包。确认启动阶梯正确、Fill 后撤旧单并重报偏移价。原文测试提到“tick 一次产生阶梯”，与要求放在 on_start 有歧义，应按实际生命周期明确测试。

---

<a id="exercise-4-build-a-noise-trader"></a>

## 练习 4：实现噪声交易者

真实市场中，基金流入、工资扣款投资、指数换仓、赎回或套现等活动并不来自短期价格观点。撮合引擎看到的像随机买卖，学术上称 noise，与 informed order 相对。

模拟 Noise_trader 代表这类背景活动，不以盈利为目标。随机选择方向、数量、价格和有效方式，让做市商有对手、产生 Fill/BBO/Trade，其他策略才有事件可观察。

参与者行为多样，既有急于成交的 IOC，也有设目标价等待的 Day，应随机化有效方式。

在 app/bots/src/noise_trader.ml 实现 Bot，配置：

- symbols 列表。
- mean size，单笔在其附近小范围抽样。
- tick_chance∈[0,1]，控制每 tick 是否下单。
- aggressiveness_pct：可立即成交或远离最优价挂单的概率。
- ioc_pct：IOC 与 Day 的比例，Day 积累有利于后续实验。

on_tick：

1. 随机数超过 tick_chance 则不操作。
2. 均匀选 symbol。
3. 均匀选 Buy/Sell。
4. 在均值附近抽样数量。
5. 按积极程度选择对手最优价外几分的可成交价，或本侧最优价外的挂单价；空簿回退 oracle。
6. 按 ioc_pct 选择 Ioc，否则 Day。

runtime 不维护 BBO，bot 的 on_event 用 Symbol.Table 缓存 BBO 更新。所有随机选择都用 Context.random，以保证 seed 可复现。

**测试：** 用 make_recording_bot 驱动若干 ticks、print_submitted，固定 seed，检查买卖组合、数量和可成交比例符合预期。

---

<a id="exercise-5-wire-up-the-calm-day-scenario"></a>

## 练习 5：接通平静日场景

Calm_day.configure 目前是 stub。填成单证券、一个做市商、一个噪声交易者、平稳 oracle。

每场景独立模块，符合 Scenario.S，在 jsip_scenarios.all 注册后自动出现在 -scenario 参数中。

1. 替换 configure 的 TODO，生成 Scenario_config.t：如 AAPL；oracle 波动约 3 分/秒，均值回归强度约 0.05；news=[]；bots 放两种策略。构造 oracle 可参考 test_bots.ml。
2. 看 Bot_spec 如何包装 module、Config、参与者、RNG seed 和 tick 间隔。
3. 构建后运行：

```sh
dune exec app/scenario_runner/bin/main.exe -- -scenario calm-day
```

第二个终端：

```sh
dune exec app/monitor/bin/main.exe
```

应持续看到 BBO/ACCEPTED/FILL/TRADE。

**提示：** 用 monitor 的类别和文本过滤定位。没有成交可能是 bug，也可能半价差太大/噪声不够积极；调整 half_spread_cents 或 aggressiveness_pct。簿不积累可能 tick_chance 太低或 num_levels 太少。

---

<a id="exercise-6-build-a-momentum-trader"></a>

## 练习 6：实现动量交易者

真实短时价格有时沿一个方向持续：多位参与者响应相同新闻，后续继续推价。动量/趋势跟随策略尝试识别这种走势，从人工看图到扫描上千股票的系统都有。

本教学 bot 看公开成交序列，持续同向移动时跟随下单。策略状态跨多条事件，而非只看当前快照。

在 momentum_trader.ml：

- on_event 维护最近 N 个 Trade_report 的固定长度窗口。
- on_tick 计算最新价格减最早价格；未满窗口不交易。
- 信号绝对值低于 threshold_cents 不交易。
- 超阈值提交同方向 IOC，数量随信号强度增加。

难点是固定长度环形窗口的更新。

**配置：** symbol、窗口容量、分为单位的阈值、单笔数量上限。大窗口更平滑但反应更慢。

**提示：** 用公开 Trade_report，不用只涉及自己参与者的 Fill；on_event 更新状态，on_tick 做决定。

**测试：** 人工成交序列让信号超过阈值，检查下单方向；窗口滚动后信号应衰减。

---

<a id="exercise-7-build-the-earnings-shock-scenario"></a>

## 练习 7：实现财报冲击场景

市场不仅渐变，财报、药物审批、CEO 离职、并购或经济数据意外会制造跳跃。利润远高于预期时，价格可能在下次可交易时迅速上升，一笔或多笔完成。

旧报价的做市商容易被信息更快的对手成交，承受逆向选择；动量者则尝试跟随跳跃。

Earnings_shock 模拟正向 fundamental 冲击，做市商、噪声、动量同时运行。

configure：

1. 一个 symbol，中等 oracle 波动。
2. 在启动约 15 秒注入 +500 分冲击，描述可为 `AAPL earnings report — stock spikes`。
3. 三个 bots，可选加入均值回归者观察其是否误判为超涨。

观察：oracle 按期跳跃；做市商更新滞后期间旧报价被成交；动量者随后跟随。

> 译注：原文对正向跳跃写成“bid 高于跳后 fundamental”，应是旧 ask 低于上涨后的合理价值、被买方迅速成交；负向跳跃才容易出现旧 bid 过高。

**提示：** 用 Time_ns.Span.of_sec；新闻描述打印 stdout，交易所反应在第二终端 monitor 观察；重算阶梯需读 Context.fundamental，不能永远缓存初值。

---

<a id="choose-your-own-adventure-more-bots"></a>

## 自选拓展：更多 bots

完成上述线性练习后，至少再新增一个独立 Bot：

- **均值回归者：** mid 高于 fundamental 足够多则卖，低则买；IOC，配置 threshold_cents/size。盲目回归策略会被真实价值跳跃惩罚。
- **Whale 巨单者：** 偶尔大 IOC 扫多档，其余安静。配置 mean_size/per_tick_chance/sell_pct，可搭配闪崩。
- **配对交易者：** 交易两相关 symbol 的相对价差，A 相对 B 贵则卖 A 买 B，反之亦然，配置相关系数。
- **时段报价者：** 在配置的非活跃时段扩大价差或停止报价，探索流动性降低。
- **散户模仿者：** 只按整美元报价、小数量、慢 tick。
- **对抗者：** 利用做市商可预测的库存 skew。先付出跨价差和持仓成本，单方向扫多个阶梯；做市商积累单侧库存后机械调价，再以更优价格完成反向交易。利润来自预测对手响应而非 fundamental 变化，是逆向选择例子。

每个新增 bot 要固定 seed 的 recording test，并至少加入一个场景。

---

<a id="choose-your-own-adventure-more-scenarios"></a>

## 自选拓展：更多场景

- **Active day：** 多 symbol、每 symbol 做市商、更高吞吐噪声。
- **Flash crash：** 短时间连续负新闻、大偏卖鲸鱼。真实例子是大机构急抛、其他人止损、做市商撤报价，卖压加速而流动性薄。可用 large fund liquidation、stop-loss cascade、dealers pull quotes 等描述，在 monitor 看级联。
- **先静后乱：** 前段平静，30 秒附近集中新闻，观察响应延迟。
- **容量压力：** 增大 tick_chance/mean_size，直到撮合成为瓶颈，后续部分研究如何稳定。

每个新模块提供 name/description/configure，在 all 增加一行即可由参数帮助发现。

---

<a id="stretch-separate-the-system-components-into-independent-processes"></a>

## 拓展：拆分成独立进程

目前交易所、bots、新闻都在一个 OS 进程，RPC 只是 loopback。把每个 bot 放入独立 binary，通过命令传 Config、连接单独服务器、沿用 runtime。进一步可把网关与撮合引擎也拆开，内部 RPC 通信，仅网关面向外部客户。这更接近生产部署。

---

<a id="stretch-real-authentication"></a>

## 拓展：真实认证

当前 login 只信任名字，Alice 未在线就能冒用；教学可以，真实系统可能导致代别人花钱。

可以按复杂度尝试：

- 预共享秘密：服务器名字→秘密映射，登录传 name/secret 比对，可从配置加载。
- Challenge-response：服务器发随机 nonce，客户用私钥签名，服务器按该参与者公钥验证；例如 Ed25519。
- TLS 客户端证书：从证书解析身份，用 TLS 封装 reader/writer 的 Async RPC 连接。

原文示例参考 tls-async/mirage-crypto、Async_extra.Tls_async 或 Rpc.Connection.client；是否存在这些 API 要以本地依赖为准。

共同原则：身份由拥有的 key/证书证明，而非口头自报。不要明文落盘秘密，至少静态存储哈希，最好避免在网络发送共享秘密本身。
