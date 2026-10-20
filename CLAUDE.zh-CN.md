<a id="claudemd--jsip-exchange"></a>

# CLAUDE.md — jsip-exchange 中文对照

> 原文：[CLAUDE.md](CLAUDE.md)。本文件供人类阅读对照，不替代当前生效的 AGENTS 或用户指令。
> 译注：原文按“课程第三周、学生已完成前面练习”编写，部分“已实现”描述与当前 checkout 不符。当前 `Price` 仍有 TODO，订单簿仍用列表，登录和取消功能未接通。请将下文的课程进度描述理解为原课程假设。

<a id="about-this-project"></a>

## 关于项目

`jsip-exchange` 是 OCaml 编写的简化交易所教学项目，供 JSIP 学生在四周内逐步扩展。学生开始使用助手时约有两周 OCaml 经验，通常即将升入大学三年级。学习是目的，交付代码是手段。

实际要求：

- 不只解释做了什么，还要解释为什么。
- 提问含糊时先确认，不要默默决定架构。
- 能指出现有代码回答问题时，优先指路，不要重写。
- 如果学生准备直接复制整个模块、跳过应理解的概念，应提醒。

JSIP 结束时学生应能做到：

- 技术方面：写符合惯例的清晰代码并在 review 中解释；拆分大项目并写设计计划；迭代调整优先级；通过版本控制协作；设计测试场景并写 expect tests；阅读和修改别人写的大型代码；借助 AI 学习和提高效率，同时保留自己的思考。
- 非技术方面：解释 Jane Street 的业务及计算技术在行业中的作用；理解技术面试的准备与预期；面对模糊问题，在缺少现成答案或外部帮助时继续推进。

<a id="ground-truth-code-not-docs"></a>

## 事实以代码为准，不以文档为准

项目有 README 总览和练习说明。学生修改代码后文档会过时，`.ml/.mli` 才是依据。

回答项目行为、练习要求和功能是否存在时，先读代码，再把文档当入口交叉验证。发现不一致就告诉学生；文档也是可以做代码审阅并修改的材料，不是不可质疑的权威。

> 译注：原文的 `doc/exercises-week-*.md` 在当前仓库实际对应 `exercises-part-*.md`。

<a id="build-test-format"></a>

## 构建、测试、格式化

使用外部 opam OCaml 工具链，而非 Jane Street 内部工具。标准 Dune 命令：

```sh
dune build                 # compile
dune runtest               # run all tests
dune fmt --auto-promote    # format (uses .ocamlformat: janestreet profile, margin 77)
dune build @doc            # generate odoc HTML
```

常见开发循环：

```sh
dune build && dune runtest                # the usual cycle
dune exec app/server/bin/main.exe -- -port 12345 -seed-market-maker
dune exec app/client/bin/main.exe -- -port 12345 -name Alice
dune exec app/scenario_runner/bin/main.exe -- -scenario calm-day -port 12345 -seed 0
dune exec app/monitor/bin/main.exe -- -host localhost -port 12345
```

不要修改 `_build/`：该目录由 Dune 自动生成。

<a id="code-conventions"></a>

## 代码约定

沿用仓库现有风格；没有理由不要另立一套。

<a id="documentation"></a>

### 文档

- 每个 library 都需要说明，每个 module 都需要注释，每个 mli 都需要 `(** doc *)`。
- 不写无用注释，如“把数字相加”。
- 给例子，说明与其他模块的关系。
- 字段文档紧随字段：`field : type (** doc *)`。
- 文档内用 `[code]`、`{[blocks]}`，链接用 `{!Module.foo}`。
- 查看 odoc 渲染结果。
- `(*_ *)` 会被文档工具忽略。

<a id="naming"></a>

### 命名

- 作用域短，名字也可以短。
- 布尔名用 `is_foo`，不用 `check_foo`。
- 会抛异常的函数以 `_exn` 结尾。
- 资源获取/释放用 `with_`，符合 try/finally 模式。
- 使用美式英语和 `snake_case`。
- `_` 仅用于未使用的值。
- `unsafe` 留给可能产生段错误的操作；仅跳过检查的叫 `unchecked`。
- 避免 `dont_foo` 等否定布尔名。
- 常量命名并拆成有意义的部分。
- 类型参数通常用 `'a/'b`，有特殊含义时可用 `'ok/'err`，Map 用 `'k/'v`。

<a id="printing"></a>

### 打印

- 优先 `[%string "x is %{x}"]`，不用普通 sprintf。
- `ppx_custom_printf` 使用 `sprintf !`。
- 总是派生 `sexp_of`。
- 给人读的诊断优先 `[%message]`，而不是 `[%sexp]`。

<a id="testing"></a>

### 测试

- 测试应容易阅读，使用 expect tests，放在独立 test 目录。
- 测试专用功能放进 `For_testing`。
- 部分 inline tests 用于演示。
- 文件叫 `test_<module>.ml`，位于 `lib/<x>/test/` 或 `app/<x>/test/`。
- 使用 `let%expect_test` 与 `[%expect]`；布尔性质测试可用 `let%test`，不比较打印输出的可用 `let%test_unit`。参考订单簿测试。
- 复用 `lib/test_harness/` 的参与者常量、订单构造器和打印器。
- 更新预期用 `dune runtest --auto-promote`，但先读 diff。意外差异可能暴露真实问题。

<a id="interfaces"></a>

### 接口

- 大多数模块都有 `type t`，主要类型通常叫 `t`。
- 参数顺序：可选参数、t、位置参数、带标签参数。
- 不明确的参数应加标签。
- 可选参数应谨慎使用，大 API 和测试除外。
- 不引入新的中缀运算符，不建泛泛的 `helpers.ml`。
- 避免 functor，原文建议在确有需要时考虑 first-class modules。

<a id="managing-namespaces"></a>

### 命名空间管理

- 只 open 设计为可 open 的模块，例如 `Let_syntax/O/Composition_infix`。
- 在需要 Async 的库里一致地 open Async，避免打印缓冲混用。
- 中缀操作用 O；没有 O 就用前缀。
- 公共类型放 `_intf.ml`。
- 设置 library 的顶层模块；小库可以只含一个模块；有时可完全不公开实现。
- 尽量不做模块别名，必须做时保持同名。
- 导入方式按文件或按库统一选一种。

<a id="style-preferences"></a>

### 风格偏好

- 短的 match 分支在前，优先 match 而不是 if。
- 避免 `else ()`；除 monad 场景外不使用 `let...and...`。
- 优先类型注解而非反复写模块路径；多态函数或离注解很远时可用路径。
- 不用 `M.{ ... }` 构造 record，它与 `[@@deriving fields ~getters]` 不兼容。
- 普通变体优先于多态变体。
- 用 `f();`，而不是 `let () = f()`。
- 接收 `Source_code_position.t` 的函数传 `[%here]`。
- 路径拼接用 `^/`，时间优先 `Time_ns`。
- 使用 `flag_optional_with_default_doc_sexp`。
- 复杂辅助逻辑按原文建议就地展开；使用 `Staged.t` 前仔细判断。
- 变体改变会影响 sexp。
- 原文警告：`when` 配合可变字段可能引发段错误；guard 保持简单。

<a id="avoiding-error-prone-idioms"></a>

### 避免易错写法

- 对变体匹配不写通配分支 `| _ ->`，让编译器检查遗漏。
- 被忽略的结果应写类型，record 字段、带标签参数和构造子参数除外。
- 使用返回值。
- 不用多态 compare。
- 多态变体可用 as 模式，如 `` (`A | `B) as mode ``。

<a id="error-handling"></a>

### 错误处理

- 明确错误类型，接口不声明 exception。
- 抛异常的函数采用 `_exn`，显式写出 `ok_exn`。
- 资源生命周期用 with_，不要吞掉调用方异常，使用 `Monitor.protect`。
- 验证人类输入的 sexp/json；原文认为机器格式 bin_io 不必额外验证。
- 收集所有错误，添加上下文。
- 库内部前置条件违例：`raise_s [%message "..." (x : T.t)]`。
- 模块边界可能正常失败的操作，尤其 RPC，返回 `'a Or_error.t`，用 `Or_error.error_s [%message ...]` 构造错误。
- 留给学生的占位实现用 `failwith "TODO: implement <thing>"`；学生没有要求时不要悄悄填完。
- 可以用 Or_error 时，不直接使用 Result.t，与仓库一致。

<a id="monads"></a>

### Monad

- 优先 `let%bind` 而非 `>>=`。
- 每个作用域一个 Let_syntax，或用 `let%bind.Module`。
- 不引入无意义的 monad。
- `return ()` 前用分号连接前面的动作。
- 优先 `don't_wait_for` 而非 upon，便于以后演进。

<a id="opens"></a>

### Opens

```ocaml
open! Core              (* always, for every src/test/bin .ml *)
open! Async             (* in libraries that use Async — gateway, bot_runtime *)
open Jsip_types         (* in libraries that use the core domain types *)
```

`!` 抑制 unused-open 警告。不要把 Core 换成 Stdlib，也不要逐个 open Core 的子模块。

<a id="dune-files"></a>

### Dune 文件

library 使用统一结构：

```
(library
 (name jsip_<x>)
 (public_name jsip-exchange.jsip_<x>)
 (libraries <deps>)
 (preprocess (pps ppx_jane)))
```

测试：

```
(library
 (name jsip_<x>_test)
 (libraries jsip_<x> ... jsip_test_harness core)
 (inline_tests)
 (preprocess (pps ppx_jane)))
```

新增 library 照此模式，确认目录能被发现；有 dune 文件时 Dune 通常自动发现。

<a id="project-layout"></a>

## 项目布局

```
lib/
  types/             domain types (Side, Price, Size, Symbol, Order, Fill, ...)
  order_book/        Order_book + Matching_engine
  gateway/           RPC, session, dispatcher, protocol parsing
  bot_runtime/       Bot scaffolding (on_tick / on_event callbacks)
  fundamental/       Ornstein-Uhlenbeck fundamental-price process
  news_injector/     scheduled market shocks
  test_harness/      shared test helpers
app/
  server/            exchange RPC server binary
  client/            interactive CLI client
  market_maker/      seed market maker library
  bots/              student-written trading bots (mostly empty in starter)
  scenarios/         named scenarios (Calm_day, Active_day, Earnings_shock, Flash_crash)
  scenario_runner/   CLI that boots a chosen scenario
  monitor/           bonsai_term TUI subscribing to the audit log
doc/
  exercises-week-{1,2,3,4}.md   per-week exercise specs (treat code as truth)
README.md            project overview
```

存在基准测试时，放在 `lib/<x>/bench/`，例如订单簿 benchmark。

<a id="what-students-have-already-implemented"></a>

## 学生可能已经实现的内容

原文假定当前是第三周开始，学生可能完成第一周和第二周前三个练习。提出实现建议之前先检查；已有的功能不要重写，应带学生看代码。

<a id="week-1-all-of-it"></a>

### 第一周：全部

原课程预计已完成：

- Price 两个比较函数。
- 价格时间优先 find_match。
- Symbol 大写字母数字校验。
- Fill.to_participant_view。
- 收盘取消 Day。
- GTC/FOK。
- Exchange_command 类型化命令分派。
- 防自成交。
- 用 Map 替代列表订单簿。

<a id="week-2-exercises-13-only"></a>

### 第二周：仅练习 1–3

原课程预计已完成：

- login、session 注册与 pipe、session feed、取消 RPC、客户端订单 ID。
- 按 symbol 跟踪库存的动态做市商。
- 做市商迁移到 Bot_runtime.Bot。

<a id="what-students-_may-not_-have-done-yet"></a>

### 学生可能还没有完成的内容

- 第二周 4–7：噪声交易者、平静日、动量交易者、财报冲击，课后借助 AI 完成。
- 空的 `app/bots/src/jsip_bots.ml`。
- 四个场景的 configure TODO。
- `app/monitor` 的工作。
- dispatcher/session 中 `Pipe.write_without_pushback_if_open` 对慢消费者缺少缓冲约束，第三周会研究。

<a id="stub-conventions"></a>

## 占位实现约定

供学生补充的 stub：

```ocaml
let foo () = failwith "TODO: implement Foo.foo"
```

上方注释说明目标和原因。不要在学生没要求时补完。学生问该函数做什么，应解释“这是待实现入口”，再按注释和上下文说明意图。

<a id="when-the-student-asks-you-to"></a>

## 当学生提出这些要求时……

- **解释代码：** 读取实际文件，引用行号，不靠函数名或文档猜测。
- **修 bug：** 先弄清当前与预期行为，帮助学生明确问题。
- **新增功能：** 先查相同或相近实现。做市商是参考，场景配置由 Scenario_config 和 Bot_spec 组装。原文称动态做市商已完成，但当前 checkout 应另外检查。
- **写测试：** 优先补现有 test_X，复用 Harness；不能在测试里重写被测算法，形成只证明自身的测试。
- **做计划：** 多文件修改可考虑先进入 plan mode，让学生审阅方案。

<a id="a-note-on-this-file"></a>

## 关于本文件

CLAUDE.md 本身也属于项目。如果约定错误、过时或不完整且影响建议，应告诉学生，由他们决定更新。
