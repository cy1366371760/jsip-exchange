(** Loads the provider-independent integer CSV exported by Python ingestion.

    Schema v1 uses the exact header:
    [symbol,date,open_cents,high_cents,low_cents,close_cents,volume_shares].
    Dates are YYYY-MM-DD, prices are integer hundredths of CNY and volume is
    integer shares. Prices remain raw and unadjusted. Only A-share symbols
    (six digits followed by .SH, .SZ or .BJ) are accepted.

    This deliberately restricted CSV has no quoted fields or embedded commas.
    It is a cross-language contract, not Tushare's wire representation. *)

open! Core

(** Validates the schema, row widths, numeric ranges, OHLC invariants and
    uniqueness of (symbol, date). Returns ascending date/symbol order.
    Header-only input is an empty history. Errors include the line number. *)
val decode : string -> Historical_bar.t list Or_error.t

(** File I/O at the application edge; read and decode errors are explicit. *)
val load : string -> Historical_bar.t list Or_error.t
