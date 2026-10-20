# Tushare historical data in JSIP

The historical-data path is runnable independently of the simulated exchange:

```text
Tushare daily → Python export → integer CSV → Historical_csv.load
             → Historical_bar.t → Historical_replay.iter → OCaml consumer
```

The ingestion code is in the parent workspace's `py-ingest/`. Python owns
credentials and requests; the JSIP OCaml executable owns loading, validation,
ordering and consumer delivery. Existing simulated fundamental prices continue
to be supplied by `Fundamental_oracle` through `Bot_runtime.Context.fundamental`.
Historical observations have a separate callback because they are information
for a strategy, whereas the matching engine accepts orders submitted by one.

## Run with real data

From `/Users/cyoung/Desktop/ocaml_trading`, use a Python environment that already
contains Tushare and pandas. The existing stocks_tracer environment works:

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

`TUSHARE_TOKEN` is read from the process environment or the parent's untracked
`.env`/`backend/.env`. Never put it in command arguments. The explicit HTTP flag
uses the official SDK transport authorized by the account owner.

The exporter queries `trade_cal`, selects the last N sessions strictly before
`as_of`, and requests only `ts_code,trade_date,open,high,low,close,vol` from
`daily`. It paginates and shares the existing retry/rate limiter. No implicit
requests happen when JSIP replays a file. Suspended stocks can have fewer than N
bars; missing entire symbols, empty histories, and invalid rows fail explicitly.

## File contract (v1)

```csv
symbol,date,open_cents,high_cents,low_cents,close_cents,volume_shares
000001.SZ,2024-01-02,909,922,905,921,52627158
```

The exact header identifies the schema. Fields cannot contain commas or quotes.
Dates are ISO dates. Prices are raw, unadjusted CNY hundredths using JSIP's
existing `Price.t`; `9.09` is 909. Tushare `vol` is hands, multiplied by 100 to
produce integer shares. No rounding is performed. Sub-cent prices and fractional
shares are rejected. This slice targets A-share `daily`; ETF prices can require
mill precision and must not be rounded into this cent-based format.

The SDK already returns numerical values through pandas. The exporter converts
their decimal string representations with `Decimal(str(value))`; it does not
claim to recover the original JSON lexemes. The native JSON fixture decoder
continues to parse original number text directly. Both paths enforce exact
cent/share representation at the JSIP boundary.

`Historical_csv.load` validates the header, column count, symbol, date, integer
ranges, OHLC bounds, nonnegative volume and unique `(symbol,date)` keys before
any consumer runs. It returns ascending date/symbol order. `Historical_replay`
delivers one complete, provider-independent bar per callback without clock
delays. To study or replace the consumer, start with
`app/historical_replay/bin/main.ml`; its callback receives `Historical_bar.t`.

## Offline tests

```sh
opam exec -- dune build app/historical_replay/bin/main.exe
opam exec -- dune runtest lib/market_data/test
opam exec -- dune exec app/historical_replay/bin/main.exe -- \
  -input lib/market_data/test/fixtures/historical_bars.csv
```

From the parent directory:

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=py-ingest/src \
  /Users/cyoung/Desktop/stocks_tracer/backend/venv/bin/python \
  -m unittest discover -s py-ingest/tests -v
```

The Python contract test exports JSIP's JSON fixture and compares it byte for
byte with its checked-in CSV. The OCaml test loads that same CSV and compares
the resulting bars with the JSON decoder's bars before replaying them. Tests
require neither credentials, Internet access nor a database.

PostgreSQL storage, adjustment factors, strategy decisions, execution and
backtest accounting remain separate future tasks.
