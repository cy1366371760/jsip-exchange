(** A provider-independent historical OHLCV observation.

    Historical bars describe an observed market; they are not orders and do
    not imply anything about the exchange's order book. *)

open! Core
open Jsip_types

type t = private
  { symbol : Symbol.t
  ; date : Date.t
  ; open_ : Price.t
  ; high : Price.t
  ; low : Price.t
  ; close : Price.t
  ; volume_shares : int64
  }
[@@deriving sexp, equal]

(** Creates a bar after checking that prices are positive, volume is
    non-negative, and the high/low contain the open and close. *)
val create
  :  symbol:Symbol.t
  -> date:Date.t
  -> open_:Price.t
  -> high:Price.t
  -> low:Price.t
  -> close:Price.t
  -> volume_shares:int64
  -> t Or_error.t

(** Orders bars by date and then symbol. *)
val compare_chronologically : t -> t -> int

(** A compact, currency-neutral representation intended for diagnostics. *)
val to_string : t -> string
