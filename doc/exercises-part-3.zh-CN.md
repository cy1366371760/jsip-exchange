<a id="jsip-exercises---part-3"></a>

# JSIP 练习：第三部分

> 对照：[英文原文](exercises-part-3.md)。下文保留原课程的团队协作和工程要求；它不表示当前个人项目要立即扩展到多人协作、网页仪表盘或对抗策略。
> 译注：涉及真实环境权限、Git 重置、合并和部署的命令仅为原课程对照材料，本轮翻译没有执行这些操作。

第三部分有两个转变：

- 从个人到小组：三四个人在共享 GitHub 仓库贡献代码，互相 review，将合并后的 bots/scenarios 复制回个人仓库。
- 从功能到生产工程：故意构建“行为异常”的 bots，暴露负载下的资源问题，再保护其他正常客户。

本部分开始用 Claude Code；默认可以借助 AI，专门的 AI 提示强调它容易出错、review 应格外留意之处。

**学习目标：** 协调分支保护、PR 和 RPC 兼容；从内存/延迟/Pipe 占用考虑系统；制造资源病态行为并防御；权衡限制与正常客户体验；借助 AI 但仍由人类负责架构，并同样认真审阅同伴的 AI 代码。

---

<a id="section-0-group-setup"></a>

## 第 0 节：小组准备

<a id="0a-your-group-and-shared-repo"></a>

### 0a：小组与共享仓库

课程通过 Slack 分配三四人小组，提供含起始代码及部分已完成练习的共享仓库。

每人保留个人仓库继续开发交易所；小组仓库额外保存大家同意共享的 bots/scenarios。

1. 小组仓库 clone 到与个人仓库不同的目录。
2. 全新 clone 后确认 dune build/runtest 都过；有问题先共同修复。

<a id="0b-reconcile-your-rpc-protocols"></a>

### 0b：统一 RPC 协议

独立开发后 Request、Exchange_event、Time_in_force 和 RPC 可能不同。例如一侧有 client_order_id、一侧没有，二进制数据就不能互读。

网络上传的不是 OCaml 值，而是序列化字节。这里用 bin_io/binprot，`[@@deriving bin_io]` 生成读写代码。双方必须同意 record 字段顺序、构造子集合与顺序、每层嵌套类型。

test_rpc_shapes.ml 使用 Rpc.Rpc.shapes/Rpc.Pipe_rpc.shapes，打印 query/response/pipe error 类型布局摘要。摘要是类型结构的固定长度十六进制指纹；字段、构造子或嵌套类型变化可能使其改变。一致摘要可作为对应 RPC 客户端兼容的重要检查。

先给起始文件未覆盖的 login/session_feed/cancel 等 RPC 增加测试，照现有模式运行 auto-promote，再比较。

统一流程：

1. 每人在个人仓库运行 gateway 测试，确认 expect 摘要最新；变化先核对再 promote。
2. 将各人的 expect 块和小组仓库版本并列放进共享文档。
3. 逐 RPC 比较，全同即完成。
4. 不同就查字段名/字段集合、Exchange_event/Time_in_force 构造子、Client_order_id 表示、RPC version 等。
5. 小组共同选标准结构；不符合者迁移，直到摘要一致；共享仓库变更通过 PR。

**AI 提示：** 重命名和全库机械迁移适合交给 Claude；选哪种变体/协议作为标准由小组决定。

<a id="0c-working-with-the-group-repo"></a>

### 0c：共享仓库工作流

个人仓库可能直接提交 main；共享仓库采用分支和 PR。

**分支：** 指向提交历史的名字，main 是正式版本。新建分支隔离工作：

```sh
# Make sure you're up to date with main before branching:
git checkout main
git pull

# Create a new branch and switch to it. Use your-name/short-description.
git checkout -b alice/book-filler

# Do your work, commit normally:
git add app/bots/src/book_filler.ml
git commit -m "Add book-filler bot"

# Push the branch to the group repo:
git push -u origin alice/book-filler
```

第一次 push -u 设置上游跟踪，以后 push 可省参数。若误提交到 main，原文演示把提交转到新分支：

```sh
git switch -c my-local-branch   # branch now points at the same commits
git switch main
git reset --hard origin/main    # rewind main back to the remote's state
git switch my-local-branch
```

> 译注：上面原文包含历史重置操作。个人工作区有未保存改动时不可照抄；这里只用于理解 Git 分支关系。

**PR：** 提议将分支合入 main。push 后打开 Git 提供的链接或 GitHub 提示，填标题、设计说明及 AI 使用情况，选择同伴 reviewer。

GitHub CI 在新机器 checkout 分支、运行 build/runtest。失败后本地修复并 push，同一 PR 会更新。

**分支保护：** main 要求非作者的一人批准、全部 CI 通过、禁止 force push。这避免无人检查的代码合并，也保证同伴拉取 main 可工作。

**Review：**

1. 阅读 Files changed 的每个文件，可逐行评论。
2. 需要实测时本地拉分支：

```sh
git fetch
git checkout alice/book-filler
dune build
dune runtest
# …then exercise the scenario, etc.
```

3. Review changes 选择 Comment、Request changes 或 Approve。满足批准和 CI 条件后作者才合并。

**合并：** 默认 Squash and merge，变成 main 上一个易回退提交；删已合并分支，下次重新拉 main 再开分支。

参考：[分支](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-branches)、[创建 PR](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)、[Review](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/reviewing-proposed-changes-in-a-pull-request)、[保护分支](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)。

第 0 节统一 RPC 和第 1 节 bots 都使用此流程。

---

<a id="section-1-the-pathological-bots"></a>

## 第 1 节：异常行为 bots

真实交易所必须假设部分客户行为异常。多数并非恶意，而是策略死循环、估值漂移不断发单、测试误连生产、订阅后卡住；也可能有人用垃圾请求拖慢对手。

交易所仍要为正常客户服务。本节构建可重复的异常 bots，分别压订单簿、请求队列、订阅 pipe、撤单路径。每 bot/scenario 一个文件、一份 PR，让同伴 review 后共享。第 2 节用 dashboard 看资源影响，第 3 节实施防御。

<a id="1a-botscenario-assignments"></a>

### 1a：分配 bot/场景

四种必做 bots，四人各一个，三人时合理分配两项；Book_filler 和 Slow_consumer 较小，可由同一人负责。

1. Book_filler：快速堆积 Day 挂单，压簿内存及查找/快照延迟。
2. Spammer：每 tick 突发大量提交，压队列、每事件分派 CPU 和订阅带宽。
3. Slow_consumer：登录订阅后很慢读取或完全不读，压服务器缓冲。
4. Cancel_storm：提交立刻撤，循环，压取消、事件和重复 ID 记账。

每种配一个独立场景：Book_fill、Order_spam、Slow_consumers、Cancel_storm；可加入做市商或噪声，约 30 秒内表现出资源问题。

可以启动多个异常 bot 副本，使用不同参与者/seed；如需多副本才明显，在设计说明写清，Config 应支持独立调参。

还可自行设计：

- 大量贴近 BBO 但永不可成交的小单。
- 反复订阅/退订。
- 在 session feed 读取中断连接。
- 紧循环查 Book。
- 巨单单次产生大量 Fill。

**测量 bots 是另一类：** 它们代表无辜客户，用于测附带伤害，应与异常 bot 同场运行。

- Latency_amplifier：随机间隔单笔提交，打印延迟分位数，与 spammer 同跑。
- Resource_canary：周期性查簿并报告往返时间。

mli 要说明是观察者，不是异常流量制造者。译注：submit 入队响应时间和最终引擎处理时间是不同指标，应明确测量终点。

<a id="1b-implementing-a-pathological-bot"></a>

### 1b：实现异常 bot

沿用 Bot_runtime.Bot。先在 mli 写行为和 Config 文档：

- 产生哪些事件、按什么节奏。
- 每字段的单位、默认值、调节用途。

这让 reviewer 能核对实现，让同伴能调参。所有可变行为都走 Config，不在 ml 硬编码 50 等数字。至少配置 symbols 和强度，如 orders_per_tick、sleep、submit/cancel 周期；价格/数量/订阅选择按所需场景明确。

**AI 提示：** Claude 熟悉支架，但容易破坏 seed 可复现、把“突发 spam”写成每 tick 仅一次提交、每次撤单循环重用同一客户端 ID。随机统一用 Context.random；Cancel_storm 每轮分配新 ID，否则之后全被重复检测拒绝。测试应证明真的施压，而不只是重复 bot 自身逻辑。

<a id="1c-one-pr-per-botscenario"></a>

### 1c：每个 bot/场景一个 PR

1. 从 main 开分支。
2. 新 bot 放 app/bots/src。
3. 新 scenario 放 app/scenarios/src 并注册 all。
4. 至少 recording test 驱动数个 ticks、验证请求；cancel storm 还检查 cancel；slow consumer 可测试 read_now_at_most 的读取节奏。
5. push、PR、请同伴 review，不能自行无批准合并。

Reviewer 应：

- 本地跑场景至少一分钟，看 monitor、服务器 RSS 和其他客户体验。RSS 是进程驻留内存，htop 可按 main.exe 筛选；尝试用另一客户端单笔提交，看是否被拖慢。
- 阅读 bot 而非仅 scenario。核对是否修改 bots/scenarios 之外的 lib、dune-project 或无关 app；这些通常超出本 PR 范围。
- 检查风格漂移：Stdlib.List、裸异常、陌生 Deferred/Pipe 写法、重复实现已有 helper；与现有 bot/做市商比较。
- 检查同义反复测试：把请求交给 bot，再检查同一对象被记录，并不能证明预期压力。应核对独立可算的订单数、数量分布、价格范围。
- 至少指出一项值得质疑的内容；若代码确实无问题，就说明测试证明了目标并批准。
- 对大量 AI 生成的 diff 多花时间。

**如实报告 AI 使用：** PR 描述写提示内容、AI/人类分别写了什么、第一稿哪里被纠正、哪些部分最不确定。不是禁止 AI，而是为 reviewer 标出理解薄弱点。

<a id="1d-copy-the-bots-and-scenarios-into-your-repo"></a>

### 1d：复制回个人仓库

小组 main 合并后，本地同步：

```sh
git checkout main
git pull
```

再用 cp 将 bots/scenarios 复制到个人仓库对应目录，确认个人仓库 build 仍通过。

<a id="section-2-build-a-monitoring-dashboard"></a>

## 第 2 节：监控仪表盘

异常 bots 准备好后，每人需要看见资源压力。本节以高层目标驱动 Claude 构建产品，关注实际结果；但明确教学目标是学习 Bonsai，单纯 stdout 不能替代 UI。

Bonsai 是 Claude 较容易给错建议的库，所以要认真验证。每人在个人仓库独立构建 dashboard，因为底层 instrumentation 可以不同。

<a id="2a-scope"></a>

### 2a：范围

独立 binary，例如 app/dashboard，使用浏览器版 bonsai_web。已有 monitor 用 bonsai_term，状态管理思路相通，但网页可用 HTML/CSS，有更灵活布局。

运行时术语简述：

- Heap 内存堆：运行时管理的对象区域，不是同名堆数据结构。
- Word 机器字：64 位机器通常 8 字节；双 int record 常约三 words（头部加字段）；50,000 live words 约 400KB。
- GC 垃圾回收：回收不再可达对象，分配多可能引入暂停和尾延迟。
- Collection：一轮回收，按堆分别计数。
- Minor/major heap：新对象先进入小、频繁廉价回收的 minor；存活者晋升到 major，回收成本更高。

> 译注：这只是教学概述，具体行为依 OCaml 版本及 GC 实现而异；不应把“所有对象都在堆、所有 GC 总会全程暂停”等简化说法当成完整运行时模型。

参考 [RWO GC](https://dev.realworldocaml.org/garbage-collector.html) 和 [Gc.stat 字段](https://v2.ocaml.org/api/Gc.html#TYPEstat)。

**必需面板：**

1. 服务器进程内存：至少每秒 Gc.stat，至少显示 live_words，保留约 60 秒滚动曲线，能区分稳定、线性和指数增长。
2. Submit 延迟：从客户调用到引擎处理完成；需要埋点。以直方图或滚动 p50/p90/p99 展示，分别对应中位及尾部阈值。
3. Cancel 延迟：同样方式。

**至少选一个额外面板：**

- 每行情/audit/session pipe 占用。
- 每参与者 orders/sec 和在簿单数。
- 某 symbol BBO 和两侧总挂单量。
- 引擎忙碌程度：队列空/积压比例；原文也建议观察相邻读取迭代间隔。

> 译注：循环间隔可能同时含等待新请求和处理耗时，不能仅凭“间隔长”断定引擎忙，应明确埋点定义。

<a id="2b-build-it-with-claude"></a>

### 2b：借助 Claude 实现

分成易审阅的两块：先 server stats RPC，再 dashboard。

<a id="general-advice-that-applies-to-both-pieces"></a>

#### 两块都适用的建议

- 多文件/UI 工作先计划目录、state 和 API，再动代码；质疑与自己设计不符的方案。
- 参考 monitor 的纯 controller 状态机加 Bonsai 渲染层；这是可以独立测试的关键分界。
- 必须实际启动界面，看 Book_fill/Slow_consumers 是否让内存面板变化；runtest 不能替代视觉验证。
- 复盘写清 AI 驱动、手写、以及查阅 Bonsai 资料纠正的部分。

<a id="piece-1-exchange-side-instrumentation"></a>

#### 第一块：服务器埋点

新增每秒推送指标 record 的 pipe RPC：

- 新 RPC，不要把资源指标塞进 Exchange_event 并走 audit。交易事件与基础设施统计不应混淆。
- 恰好暴露面板所需的内存、submit/cancel 延迟和所选扩展指标。record、延迟表示和测量位置都需 review。
- 新 RPC 的形状也加 expect test。

<a id="piece-2-the-dashboard"></a>

#### 第二块：Dashboard

放 app/dashboard，纯 controller 加 Bonsai 层。订阅 stats，将快照折叠进滚动窗口状态并渲染。AI 可写大部分，人负责计划、运行验证和识别伪造的 Bonsai 模式。

<a id="2c-calibrate"></a>

### 2c：校准

开 dashboard，分别运行每个异常场景，记录：

- 内存有界、线性还是指数增长？
- submit/cancel 分位数如何变化？
- 额外面板是否揭示更多问题？

这些实测结果决定下一节修什么，避免泛泛加限制。

---

<a id="section-3-make-the-exchange-survive"></a>

## 第 3 节：让交易所承受异常行为

已有异常 bots、dashboard 和退化记录。此节回个人仓库独立防御。按实际问题选题，3a/3b/3c/3d 每类至少一项，依赖关系另行说明。

使用 Claude 时：

- 各小节大多独立，可并行做，但不能不读 diff 就提交。
- 自己做 reviewer：检查越界改动、风格漂移和同义反复测试。无法解释一行就停下来问。
- 每项必须有“修改前失败、修改后通过”的回归测试。
- 修复应让对应 dashboard 曲线/占用改变；不改变可能是实现或测量错。
- 如实记录 AI 与人类分工和纠正点。

**所有限制都是取舍：** 大阶梯可能是合法做市，撤单限速可能伤正常高频报价，断开慢客户可能伤弱网络用户。每项记录：

1. 限制值和单位。
2. 受影响的合法工作流。
3. 对手交易所不设限制会如何吸引该客户，为什么仍值得限制。

<a id="3a-bounded-pipes-where-unbounded-buffering-hurts-most"></a>

### 3a：有界 Pipe——无界缓冲最伤人的地方

Buffer 是生产事件到客户读取之间的内存；生产消费不同步，必然需要，但无界会耗尽内存。

Backpressure（背压）让慢消费迫使生产放慢。Pipe.write 返回待完成 Deferred，let%bind 可以等待；write_without_pushback 明确绕过它，缓冲就需要另行约束。

先看 dispatcher 的 push_market_data 和 session 的 push，使用 write_without_pushback_if_open。Pipe.create 默认 budget 为零，普通 write 有缓冲就会施加背压，但无背压写法绕过预算。因此行情和 session 慢读者可能无限积压。

> 译注：本节“每条写入都绕过背压”指这里讨论的出站订阅路径；当前服务器入站请求队列已有 budget=1024 和可等待写入。

<a id="3a1-bound-each-pipe-and-pick-a-policy-when-full"></a>

#### 3a.1：给每条 Pipe 设上限并选满载策略

可选：

- 阻塞生产者：改 Pipe.write；但 fan-out 一事件多订阅者时，一个慢客户可能拖慢全部，不宜盲目使用。
- 丢最新：保留前 N 个，客户错过新消息。
- 丢最旧：保留后 N 个，适合最新 BBO 比陈旧历史更有价值的场合。
- 断开慢客户：关 Pipe、日志警告、清理订阅，要求重连。

分别给行情和 session 选策略，不必相同；在 mli 记录，预算走 Dispatcher.create，再从 Exchange_server.start 配置传入。

测试：订阅但不读，dispatch 超过 budget 的事件，用 read_now_at_most/length_now 检查。丢新保留前 N，丢旧保留后 N，断开应关闭且注销。也可每事件打印状态摘要，用 expect 锁定。预期必须人工构造，不在测试重写策略算法。

<a id="3a2-slow-consumer-disconnect-threshold"></a>

#### 3a.2：慢消费者持续满载阈值

即使丢旧保证内存有界，也可在持续接近满载超过 N 秒后断开，避免永远为明显损坏的客户消耗分派 CPU。

依赖 3a.1；dispatcher 或服务器周期遍历订阅 bags，关闭过久满载者。

<a id="3b-order-side-rate-and-capacity-limits"></a>

### 3b：订单速率和容量限制

分别保护 spammer、book filler、cancel storm 所施压的资源。

<a id="3b1-per-participant-resting-order-capacity"></a>

#### 3b.1：每参与者挂单上限

每 symbol 或跨 symbols 最多 N 条挂单。下一条 Day 会超限时拒绝，原文提出 Resting_order_cap 原因。

要高效维护计数，并随完全成交、撤单、收盘同步。计数放哪里先讨论。

测试超限、成交使计数下降后允许新单、收盘正确扣减。译注：部分成交但订单仍挂在簿中，条数不能提前减。

<a id="3b2-per-participant-submit-rate-limit"></a>

#### 3b.2：每参与者提交限速

submit RPC 每秒最多 N，按正常用户观测选值；超额发 reason=rate limit exceeded 的 Order_reject。

两种常见算法：

- 滑动窗口：保存最近 N 个时间戳，清理一秒前记录，未满才接受并追加。
- Token bucket：按 N/秒补 token，上限容量控制突发，每次消耗一个；比时间戳列表便宜，但仍要维护补充时间和额度。

记录选择理由。状态可挂 Session，属于网关，不让引擎知道。

测试额度内突发、同窗 N+1 被拒、时间推进后恢复、两个参与者互不挤占。多身份可绕过 per-participant 限制，后续结合登录限制。

<a id="3b3-per-participant-cancel-rate-limit"></a>

#### 3b.3：每参与者撤单限速

与提交相同，可给撤单更紧上限。决定提交/撤单分开额度，还是共享带权 messages/sec，说明取舍。

<a id="3b4-per-connection-login--session-limit"></a>

#### 3b.4：登录与 session 限制

异常客户可开多连接、多名字，保持存活。限制来源 IP 的每秒 login 调用及并发 session 总数。IP 从 peer_addr 或 initial_connection_state 的地址取得。

<a id="3b5-per-symbol-total-book-depth-cap"></a>

#### 3b.5：每 symbol 总订单簿深度上限

多人协作仍可绕过 per-participant 上限。限制单 symbol 总挂单数，或两侧总股数。

原文建议：已经很深时，不再允许会继续挂簿的请求；可成交新单仍正常匹配，不能成交的新单以 book depth cap exceeded 拒绝，客户可提高积极程度或等待簿变薄。

<a id="3c-cheaper-hot-paths"></a>

### 3c：降低热路径成本

每请求必经的撮合、fan-out、RPC handler 属于热路径。前面控制压力，这里提高承受压力的效率。

<a id="3c1-cheap-path-rejection"></a>

#### 3c.1：廉价路径拒绝

未知 symbol、无效数量等请求可在网关入队前拒绝，省引擎、dispatcher、audit 工作。

代价是审计不再保留逐条拒绝，可能损失事件调查证据。折中可以周期发布数量/汇总，而不是每条记录。

<a id="3c2-bounded-request-queues-behavior-under-saturation"></a>

#### 3c.2：请求队列饱和时的行为

已有 1024 budget，write_if_open 返回 Deferred，满载时 RPC 等待而非失败。背压是诚实的，但单个快参与者能占满队列拖慢别人。

可考虑 per-participant 槽位、最大等待超时、占用超过 X% 时拒绝准入。

<a id="3d-observability-and-audit-so-you-can-prove-the-fix-worked"></a>

### 3d：可观测性与审计——证明修复有效

<a id="3d1-reject-reason-counters"></a>

#### 3d.1：拒绝原因计数

按 Cancel_reason 和 Order_reject reason 计数，经 stats RPC 给 dashboard，区分限速、重复 ID 等，帮助识别新滥用模式。

<a id="3d2-per-participant-resource-usage"></a>

#### 3d.2：每参与者资源使用

显示挂单条数/总股数、最近一分钟提交/取消、session pipe 占用，让值班者从“有人施压”定位到具体 Spammer42。

---

<a id="section-4-debrief"></a>

## 第 4 节：复盘

两份材料：

**小组 doc/part3-debrief.md：**

1. 每 bot 的实测资源压力和出现时间，至少引用一人 dashboard 的曲线/分位数，不能仅写描述。
2. 哪些比预期严重或温和？一起跑时是否出现单独运行没有的相互作用？
3. PR review 抓住和漏掉什么？下次如何改工作流？

**个人仓库同名文档：**

1. 各场景内存、延迟和其他面板的变化/不变。
2. 选了哪些防御及对应观测。
3. 修复前后曲线/数字。
4. 尚未处理的异常及下一优先级。
5. AI 擅长/遗漏什么？小实验的验证习惯是否延续到大项目？

教师看这些才能理解学习结果，它们比 PR 链接/commit 清单更有价值。

---

<a id="stretch-let-clients-modify-orders"></a>

## 拓展：允许客户修改订单

支持 amend/cancel-replace：原地改变价格或数量，而非先撤再下。放在个人仓库；新增 RPC/事件会改变组内统一的摘要，属于独立探索，不应直接推入小组标准。

真正重要的是时间优先：只减小数量可以保留同价排队位置；加量或改价应丢失旧优先级到队尾。原生 modify 还提供原子性，避免先撤后下的空窗。

需决定：

- 用什么 ID 引用，改价后客户端和内部 ID 如何变化？
- 改价后立即可成交时，怎样进入撮合、产生什么事件？
- 新总数量不高于已成交量如何处理？修改已成交/取消订单如何处理？
- 复用或新增哪些事件，协议兼容成本是什么？

完成后改一个 bot 使用它，例如做市商尽量原地调整数量保留优先级。测试缩量保优先、改价丢优先等关键差别，协议形状测试同步更新。

---
