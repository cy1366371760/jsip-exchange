open! Core
open Jsip_types

type t =
  { symbol : Symbol.t
  ; date : Date.t
  ; open_ : Price.t
  ; high : Price.t
  ; low : Price.t
  ; close : Price.t
  ; volume_shares : int64
  }
[@@deriving sexp, equal]

let create ~symbol ~date ~open_ ~high ~low ~close ~volume_shares =
  let named_prices =
    [ "open", open_; "high", high; "low", low; "close", close ]
  in
  match
    List.find named_prices ~f:(fun (_, price) -> Price.(price <= zero))
  with
  | Some (field, price) ->
    Or_error.error_s
      [%message
        "Historical_bar.create: price must be positive"
          (field : string)
          (price : Price.t)]
  | None when Int64.(volume_shares < zero) ->
    Or_error.error_s
      [%message
        "Historical_bar.create: volume must be non-negative"
          (volume_shares : int64)]
  | None
    when Price.(high < open_)
         || Price.(high < close)
         || Price.(low > open_)
         || Price.(low > close) ->
    Or_error.error_s
      [%message
        "Historical_bar.create: high/low do not contain open and close"
          (open_ : Price.t)
          (high : Price.t)
          (low : Price.t)
          (close : Price.t)]
  | None -> Ok { symbol; date; open_; high; low; close; volume_shares }
;;

let compare_chronologically left right =
  let by_date = Date.compare left.date right.date in
  if by_date <> 0 then by_date else Symbol.compare left.symbol right.symbol
;;

let price_to_string price =
  let cents = Price.to_int_cents price in
  sprintf "%d.%02d" (cents / 100) (cents % 100)
;;

let to_string t =
  sprintf
    "%s %s open=%s high=%s low=%s close=%s volume=%Ld shares"
    (Symbol.to_string t.symbol)
    (Date.to_string t.date)
    (price_to_string t.open_)
    (price_to_string t.high)
    (price_to_string t.low)
    (price_to_string t.close)
    t.volume_shares
;;
