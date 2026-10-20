<a id="ai-tools-intro"></a>

# AI 工具入门

> 对照：[英文原文](ai-tools-intro.md)。这是原 JSIP 课程的 Claude Code 教学流程，不替代本项目当前 AGENTS 或用户授权。菜单、快捷键和产品设置可能随版本变化，按实际界面确认；本轮仅翻译，没有登录、安装或执行 Git 操作。

课程从现在开始使用终端 AI 编程助手 Claude Code。此前你已独立学习 OCaml 和项目，也初步接触 Bonsai，现在把助手加入工具箱。

目标是用 AI 帮助学习和提高效率，但不把自己的思考全部交给 LLM。Claude 能读写文件、跑 shell、迭代到 build/runtest 通过；绿灯只消除明显编译/测试错误，**你真正的审阅才刚开始**：读 diff、质疑测试、核对惯例、观察哪些目标仍未实现。

共六步：

1. 开场讲解。
2. 安装/配置 Claude Code。
3. 获取 CLAUDE.md 和 skills。
4. 有/无 CLAUDE.md 分别实现 P&L，对比。
5. 助教带领的“AI 作为教师”练习。
6. 用 Claude 审阅自己的代码。

按顺序进行。

---

<a id="2-set-up-and-configure-claude-code"></a>

## 2. 配置 Claude Code

1. 在仓库根目录启动并登录：

```sh
claude
```

首次会认证，也可 /login。原课程提供 access code，选择 Claude account with subscription；可能浏览器登录再把确认码复制回终端。卡住找 TA。完成后用无修改问题验证，如“lib/order_book 做什么？不要改代码”。

2. 打开 Learning 输出风格：

```
/config
```

选择 Output style→Learning。助手边解释 Insights，边留 TODO(human) 让你自己完成小段代码；这样人仍参与思考。

项目设置保存在 .claude/settings.local.json。想所有项目默认如此，可在用户 ~/.claude/settings.json 写：

```json
{
  "outputStyle": "Learning"
}
```

新 session 或 /clear 后生效。

3. 理解权限模式。原文用 Shift+Tab 切换：

- default：每次修改/命令询问，课程要求整个练习使用。
- accept-edits：自动接受文件修改，课程初期不建议。
- plan：先方案，经批准后修改，适合多文件。
- auto：多数动作自动，仍受后台安全检查。

参见 [权限模式](https://code.claude.com/docs/en/permission-modes)。

4. 预批准重复的安全命令：

```
/permissions
```

可加入 Bash(dune build:*)、Bash(dune runtest:*)、Bash(dune fmt:*)、Bash(git status:*)、Bash(git diff:*)、Bash(git log:*)。原课程要求不要预批 commit/push 或 rm/reset/checkout，保留人工确认。

---

<a id="3-install-the-provided-claudemd-and-skills"></a>

## 3. 获取 CLAUDE.md 与 skills

从课程上游拉入：

- CLAUDE.md：每 session 自动加载的项目说明，预设 Core、Or_error、expect tests、风格、学习目标；应指向现有代码，不随意重写。
- Skills：任务匹配时按需读取的指令包，如 ocaml-style、ocaml-ppx、code-review、bonsai-web、frontend-design。下午未必用到，但之后 UI 工作特别需要 Bonsai 参考。

Learning 决定“怎样教”，CLAUDE.md 决定“对这个项目知道什么”。

步骤：

1. git remote -v 检查，没有则添加课程 upstream：

```sh
git remote add upstream git@github.com:jane-street-immersion-program/jsip-exchange.git
```

2. 先提交未保存工作，git status 保持干净。
3. 拉取并合并，再推自己 fork：

```sh
git fetch upstream        # get the latest commits from the original repo
git merge upstream/main   # merge them into your local main
git push origin main      # push the result back to your fork
```

4. Ctrl+C 后重新 claude，使新 CLAUDE.md 生效；skills 按需加载。

> 译注：当前本地 origin 指课程上游，fork 指自己的仓库；以上原始命令假定 origin 是个人 fork，不能不检查 remote 就照抄。

---

<a id="4-exercise-write-the-pl-module-with-and-without-claudemd"></a>

## 4. 有/无 CLAUDE.md 实现 P&L

目标是亲自观察项目说明的效果。同一功能做两遍：先无项目记忆，再有 CLAUDE.md，对比代码与助手行为。

题目是第一部分末尾按参与者统计 P&L；已完成可换未做题。先自己读清要求，才能评估 AI。

两遍各放临时分支；分支隔离提交，未合入前不影响 main。switch -c 创建并切换，switch 在已有分支之间切换。

从干净 main 开始：

```sh
git status     # should be clean before you start
```

<a id="run-1--without-the-claudemd"></a>

### 第一遍：没有 CLAUDE.md

1. 创建分支并删除说明，让 Claude 完全读不到；仅重命名可能仍被找到。文件保存在 Git，稍后恢复：

```sh
git switch -c pnl-without
rm CLAUDE.md
```

重启 Claude。

2. 使用提示：

> 实现按参与者统计 P&L 的 lib/pnl/src/pnl.ml/mli。按参与者及 symbol 跟踪当前库存、累计成本基础（平均入场成本）和已实现现金；公开 apply_fill、更新未实现损益参考价的 apply_trade_report，以及按 symbol 明细和总计的 summary。原题描述未实现损益为 shares×(参考价−平均成本)。添加手工成交和成交报告的 expect tests，并配置 Dune。

> 译注：原题混用现金流和已实现损益，参考第一部分中文译注；Trade_report.t 等名字也要核对实际代码，不应仅按提示发明类型。

让 build/runtest 通过，但逐次读 diff 再批准。Learning 会留 TODO(human)，那些部分自己写。

3. 恢复 CLAUDE.md，再提交和保存 diff：

```sh
git restore CLAUDE.md
git add -A && git commit -m "P&L, no CLAUDE.md"
git diff main > /tmp/pnl-without.diff
```

先恢复再提交，使 diff 只含功能工作，不含说明删除。

<a id="run-2--with-the-claudemd"></a>

### 第二遍：有 CLAUDE.md

1. 回 main，新分支：

```sh
git switch main
git switch -c pnl-with
```

重启，使其读说明。

2. 用完全相同提示，再逐步读 diff，等 build/tests 过。

两遍都有解释和人类 TODO，这是 Learning；差别可能在提问、遵循 Core/Or_error/expect/mli、正确目录、复用已有逻辑，而不是输出风格本身。

3. 提交保存：

```sh
git add -A && git commit -m "P&L, with CLAUDE.md"
git diff main > /tmp/pnl-with.diff
```

<a id="compare"></a>

### 对比

将 /tmp 两份 diff 并排看，比较：

- 惯用写法：Core/Stdlib，Or_error/裸异常，expect/其他测试。
- mli 是否过度暴露内部。
- 测试是否验证手算数字，是否只是复述实现，是否在测试重写算法。
- 文件位置和 Dune 是否符合仓库。
- AI 假设是否对应真实代码。

再看行为：是否主动确认、带你看已有代码、自动沿用未在提示重复的约定。两遍共同的 Learning 行为要排除。

写下具体差异；两遍都编译通过时，这些恰是编译器检测不到的质量差别。

<a id="reflect-then-clean-up"></a>

### 反思后清理

第二遍绿灯是否真的完成：同时统计已实现/未实现吗？测试卖出平仓还是只买？apply_trade_report 真更新参考价还是 stub？

不足就写下一条精确后续提示。核心问题是“build 过了，还有什么没做？”

课程建议把有 CLAUDE.md 的那遍合入 main，并删实验分支：

```sh
git switch main
git merge pnl-with                   # bring your chosen run onto main
git branch -D pnl-without pnl-with   # delete the throwaway branches
```

---

<a id="5-ai-as-educator-exercise-ta-facilitated"></a>

## 5. AI 作为教师的练习（TA 带领）

练习用 AI 理解陌生概念，再关闭助手讲给别人，证明自己学会。

1. 两人分工：
   - A：lib/fundamental 的 OU 价格过程、离散化、波动参数的具体含义、seed 复现。
   - B：Async.Pipe 背压，以及 gateway 的 write 与 write_without_pushback 取舍。
2. 用 Claude 约 15 分钟，读代码、追问、请求心智模型/图。笔记用自己的话，不直接粘贴。
3. 关闭 Claude，各讲约 5 分钟。不会就承认并查代码，别模仿 AI“说得像真的”。
4. 讨论 AI 哪处错误被解释过程发现、自己哪处理解漏洞显现、哪些地方像教师、哪些像自信但错误的教材。

“AI 说了”不等于“我懂了”；核对代码，再自己重讲才能缩小差距。

---

<a id="6-ask-claude-to-review-your-code"></a>

## 6. 让 Claude 审阅你的代码

换成 reviewer 角色：

1. 新 session，原文这里写 Ctrl+Tab 切 accept edits，前面则是 Shift+Tab，快捷键以当前产品为准。让它检查个人 fork 相对 starter 的全部变化：

> 用 git diff upstream/main 找我新增的代码。像正式 review 一样检查正确性、惯例、测试缺失和命名，只给 review 评论和高层反馈，不改功能代码。

完成后 git diff 或编辑器 Source Control 查看评论。原文同时说“不要改代码”和“留下代码内评论”，应先明确评论交付方式。

2. 对每条意见分类：
   - 可行动：真实问题。
   - 风格小事：技术无错、收益低。
   - 幻觉：所指函数/行为不存在，查实际文件。
   - 漏掉真实问题：自己知道有错但它没提。

3. 选一条修复、一条反驳，各能用一句话说明理由。
4. 全组讨论它真正说对和说错的各一个例子，你怎么辨别。

Review 是待验证的假设清单，不是必须照做的指令。

---

<a id="further-reading"></a>

## 延伸阅读

原文列出的官方入口，保留供对照（版本变化请自行核对）：

- [Claude Code 总览](https://docs.claude.com/en/docs/claude-code)
- [最佳实践](https://code.claude.com/docs/en/best-practices)
- [Slash commands](https://docs.claude.com/en/docs/claude-code/slash-commands)
- [Memory / CLAUDE.md](https://docs.claude.com/en/docs/claude-code/memory)
- [Output styles](https://docs.claude.com/en/docs/claude-code/output-styles)
- [Skills](https://docs.claude.com/en/docs/claude-code/skills)
- [常见工作流](https://docs.claude.com/en/docs/claude-code/common-workflows)
- [Settings](https://docs.claude.com/en/docs/claude-code/settings)
