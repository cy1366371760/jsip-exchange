# Trading 212 → JSIP 账户观察数据

[英文对照](trading212-account.md)

Python 获取官方 Invest／Stocks ISA 只读数据，OCaml 通过 `Jsip_broker_data.Trading212_account` 加载私有的、有版本号的 JSON 快照。没有交易或交易所订单提交。范围以 [官方文档](https://docs.trading212.com/api) 为准，不等于能读取券商 App 每个页面。

```text
Trading 212 HTTPS API → Python → 私有 JSON／CSV
                                    ↓
                          OCaml 券商数据类型 → 研究回调
```

覆盖账户汇总、证券／交易所资料、持仓、未完成订单与详情、完整分页的历史订单／股息／资金流水、CSV 报告，以及可用时的已弃用 pies／详情。报告请求包含利息。不提供通用历史 OHLCV、CFD 历史或实时行情。

## 运行

环境变量为 `TRADING212_API_KEY`、`TRADING212_API_SECRET`、`TRADING212_ENVIRONMENT=live` 或 `demo`。已有配置加载器支持根目录 `.env`，再回退到 `backend/.env`，不会覆盖进程已有变量。不要提交凭据或账户导出。

在项目根目录，使用已有 Python 环境：

```sh
PYTHONPATH=py-ingest/src python -m qta_ingest.trading212_export \
  --output data/exports/trading212/account_snapshot.json
```

加 `--include-report` 才新建异步 CSV 任务；不加仍会下载／解析已有的已完成报告。`--report-from` 接受带时区的 ISO 时间；不指定则采用 API 中最早的历史事件。请求按最多 364 天拆分，真实接口拒绝超过一年。五次轮询可能不够，等待／失败／部分成功会明确标记。重复加参数会重复新建任务。相邻报告共享时间边界，CSV 行不是已经去重的账本。

在 `jsip-exchange` 中：

```sh
opam exec -- dune exec jsip-broker-snapshot -- \
  -input ../data/exports/trading212/account_snapshot.json
```

CLI 只打印状态／数量。先看 `trading212_account.mli`，再看实现、合成 fixture／测试，最后看 CLI。

```ocaml
let snapshot = Trading212_account.load path |> Or_error.ok_exn in
Trading212_account.iter_fills snapshot ~f:(fun fill -> ignore fill)
```

## 数据约定

- JSON 十进制数先转 `Decimal` 再导出字符串，不经过二进制 float。OCaml 用私有 decimal 字符串验证，不计算、不舍入；碎股／分币以下价格不强塞进 `Size.t`／分币 `Price.t`。
- 金额携带币种，GBX 仍是便士，不是 GBP；不擅自换汇。
- 成交按时间再按 ID 排序；读取／回放不访问网络或当前时钟。
- 常用账户记录有明确类型，来源全部字段保留在 `raw`／`datasets`。交易所／pies／报告元数据保留 JSON。CSV 按原列名保存字符串，不猜单位。部分成功的有效行保留，同时明确标注状态。
- GET 有有限重试／退避与逐接口限流，遵守配额响应头。分页拒绝循环、切换接口和缺失结束标志。报告 POST 不在不确定失败后重试，没有交易／pie 修改接口。
- 校验 TLS，禁用重定向，CDN 下载不带 Basic 凭据。错误不含正文、URL 或凭据。原子文件为 `0600`，新目录为 `0700`，不改变已有目录权限。
- 限流是进程内的，同一账户不要并行启动多个采集器。

未实现：自动接 bot 事件流、修改撮合引擎、修改组合、PostgreSQL 入库、CSV 账本去重、收益等分析。

离线检查：

```sh
PYTHONPATH=py-ingest/src python -m unittest discover -s py-ingest/tests
# 在 jsip-exchange 中：
opam exec -- dune build app/broker_snapshot/bin/main.exe @lib/broker_data/test/runtest
```

测试使用合成数据，不需要账户、token、网络或数据库。真实验证与全量构建的原有环境报错见 [中文报告](../../docs/trading212_integration_zh.md)。
