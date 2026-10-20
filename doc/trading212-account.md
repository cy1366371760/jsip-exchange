# Trading 212 → JSIP account observations

[中文对照](trading212-account.zh-CN.md)

Python retrieves official Invest / Stocks ISA read data. OCaml loads a private,
versioned JSON snapshot through `Jsip_broker_data.Trading212_account`. There is
no trading or exchange-order submission. Coverage follows the
[official reference](https://docs.trading212.com/api), not every broker App screen.

```
Trading 212 HTTPS API → Python → private JSON / CSV
                                    ↓
                         OCaml broker-data records → research callback
```

Coverage: account summary, instrument/exchange metadata, positions, pending
orders and details, complete paginated orders/dividends/transactions, report CSV,
and deprecated pies/details when available. Report requests include interest.
This does not provide general historical OHLCV, CFD history or real-time quotes.

## Run

Provide `TRADING212_API_KEY`, `TRADING212_API_SECRET` and
`TRADING212_ENVIRONMENT=live` or `demo` via environment variables. The existing
configuration loader also reads root `.env`, then `backend/.env`, without
overriding process variables. Never commit credentials or account exports.

From the project parent directory, using an existing Python environment:

```sh
PYTHONPATH=py-ingest/src python -m qta_ingest.trading212_export \
  --output data/exports/trading212/account_snapshot.json
```

Add `--include-report` to create asynchronous CSV jobs. Without it, finished
existing reports are still downloaded and parsed. `--report-from` accepts a
timezone-bearing ISO timestamp; otherwise the earliest API event is used.
Requests span at most 364 days: the live endpoint rejects more than one year.
Five polls may not suffice; pending/failed/partial status is explicit. Repeated
`--include-report` creates new jobs. Adjacent report windows share a boundary;
CSV rows are source observations, not a deduplicated transaction ledger.

From `jsip-exchange`:

```sh
opam exec -- dune exec jsip-broker-snapshot -- \
  -input ../data/exports/trading212/account_snapshot.json
```

The CLI prints only status/counts. Read `trading212_account.mli` before its
implementation, then the synthetic fixture/tests and the CLI.

```ocaml
let snapshot = Trading212_account.load path |> Or_error.ok_exn in
Trading212_account.iter_fills snapshot ~f:(fun fill -> ignore fill)
```

## Contracts

- Exact JSON decimals become `Decimal` then decimal strings, never binary floats.
  OCaml validates a private decimal string, without arithmetic or rounding.
  Fractional shares/sub-cent prices are not forced into `Size.t`/cent `Price.t`.
- Money carries currency. GBX stays pence, not GBP. No inferred FX conversion.
- Fills sort by timestamp then ID; loading/replay has no network or clock access.
- Important account records are typed; all original fields survive in `raw` or
  `datasets`. Exchanges/pies/report metadata remain JSON. CSV uses named string
  columns without guessed units. Partial valid rows survive, with explicit status.
- GET has bounded retry/backoff and endpoint pacing, respecting quota headers.
  Pagination rejects loops, endpoint changes and missing end markers. Report
  POST is not retried after ambiguous failure. Trading/pie writes are absent.
- TLS is verified, redirects disabled, and CDN downloads receive no Basic
  credentials. Errors omit response bodies, URLs and credentials. Atomic files
  are mode 0600; new directories 0700. Existing directory modes are not changed.
- Limits are process-local; avoid concurrent collectors for one account.

Not implemented: automatic bot-feed integration, matching-engine changes,
portfolio mutation, PostgreSQL storage, CSV ledger deduplication or analytics.

Offline checks:

```sh
PYTHONPATH=py-ingest/src python -m unittest discover -s py-ingest/tests
# In jsip-exchange:
opam exec -- dune build app/broker_snapshot/bin/main.exe @lib/broker_data/test/runtest
```

Tests use synthetic data, no account/token/network/database. See the
[Chinese report](../../docs/trading212_integration_zh.md) for live validation and
existing full-build environment failures.
