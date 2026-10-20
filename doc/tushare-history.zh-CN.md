<a id="tushare-historical-data-in-jsip"></a>

# JSIP 中的 Tushare 历史数据

> 英文对照：[tushare-history.md](tushare-history.md)。

历史行情路径可以独立于模拟交易所运行：

```text
Tushare daily → Python export → integer CSV → Historical_csv.load
             → Historical_bar.t → Historical_replay.iter → OCaml consumer
```

抓取代码位于父工作区 py-ingest。Python 管理凭据和网络请求；JSIP 的 OCaml 程序负责加载、校验、排序并向消费者交付。
原有模拟基本面价格继续由 Fundamental_oracle 经 Bot_runtime.Context.fundamental 提供。
历史观察值供策略读取，通过独立 callback 传递；撮合引擎则接收策略提交的订单。

<a id="run-with-real-data"></a>

## 使用真实数据运行

从 /Users/cyoung/Desktop/ocaml_trading 开始，使用已装 Tushare/pandas 的 Python 环境。已有 stocks_tracer 环境可以运行：

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=py-ingest/src \
  /Users/cyoung/Desktop/stocks_tracer/backend/venv/bin/python \
  -m qta_ingest.jsip_export \
  --symbols 000001.SZ 600000.SH --sessions 5 --as-of 2026-10-08 \
  --output data/exports/jsip_a_share_bars.csv --allow-insecure-http

cd jsip-exchange
opam exec -- dune exec app/historical_replay/bin/main.exe -- \
  -input ../data/exports/jsip_a_share_bars.csv
```

TUSHARE_TOKEN 从进程环境或父工作区未跟踪的 .env/backend/.env 读取，不要放进命令参数。HTTP flag 明确启用账号所有者已授权的官方 SDK 传输方式。

导出器查询 trade_cal，选择严格早于 as_of 的最后 N 个交易日，仅请求 daily 的 ts_code/trade_date/open/high/low/close/vol。支持分页，共用原来的限速和重试。JSIP 文件回放不会隐式联网。停牌股票可能不足 N 条；整只股票无行情、空历史或坏数据都会明确失败。

<a id="file-contract-v1"></a>

## 文件契约（v1）

```csv
symbol,date,open_cents,high_cents,low_cents,close_cents,volume_shares
000001.SZ,2024-01-02,909,922,905,921,52627158
```

精确 header 标识 schema，字段不允许含逗号或引号。日期采用 ISO 格式。
价格是未复权人民币，以整数分存入现有 Price.t：9.09 变为 909。
vol 是手，乘 100 转为整数股。不四舍五入，亚分价格或非整数股拒绝。

本切片面向 A 股 daily。ETF 可能需要厘级精度，不能强行舍入成分。

SDK 的数值已经经过 pandas。导出器用 Decimal(str(value)) 转换其十进制表示，不声称恢复了原 JSON 数字文本。原生 JSON fixture decoder 仍直接解析原始数字文本。两条路径在 JSIP 边界都严格检查分/股精度。

消费者运行前，Historical_csv.load 检查 header、列数、symbol、日期、整数范围、OHLC 范围、非负成交量及 (symbol,date) 唯一性。结果按日期、symbol 升序。
Historical_replay 每次 callback 交付一条与 provider 无关的完整 bar，没有墙钟延时。
学习或替换消费者，从 app/historical_replay/bin/main.ml 开始；callback 参数是 Historical_bar.t。

<a id="offline-tests"></a>

## 离线测试

```sh
opam exec -- dune build app/historical_replay/bin/main.exe
opam exec -- dune runtest lib/market_data/test
opam exec -- dune exec app/historical_replay/bin/main.exe -- \
  -input lib/market_data/test/fixtures/historical_bars.csv
```

父工作区运行：

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=py-ingest/src \
  /Users/cyoung/Desktop/stocks_tracer/backend/venv/bin/python \
  -m unittest discover -s py-ingest/tests -v
```

Python 契约测试将 JSIP JSON fixture 导出，与 checked-in CSV 逐字比较。
OCaml 读取同一 CSV，与 JSON decoder 的 bar 比较后回放。
测试不需要凭据、Internet 或数据库。

PostgreSQL、复权因子、策略、执行和回测记账属于后续任务。
