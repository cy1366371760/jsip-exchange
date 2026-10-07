(** Decoder for the Tushare Pro [daily] response envelope.

    This module is the provider boundary: Tushare field names, date strings,
    symbol conventions, and volume units do not escape it. *)

open! Core

(** Decodes [code], [msg], [data.fields], and [data.items]. Required columns
    are located by name, so their array positions may vary.

    Tushare prices are yuan-valued JSON numbers. Their original decimal text
    is parsed without passing through [float], and values must be exactly
    representable by the existing cent-precision [Price.t]. Sub-cent values
    are rejected rather than rounded.

    Tushare [vol] is interpreted as lots ("hands"); one lot is converted to
    100 shares. The result must be an exact, non-negative whole share count.

    Returned bars are ordered by ascending date and then symbol. Prices are
    raw, unadjusted daily prices; applying [adj_factor] is outside this
    decoder. Non-zero Tushare codes and malformed responses return [Error].
*)
val decode : string -> Historical_bar.t list Or_error.t
