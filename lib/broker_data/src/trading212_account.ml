open! Core
open Jsip_types

type decimal = string

let decimal_to_string t = t

type money =
  { currency : string
  ; amount : decimal
  }

type instrument =
  { symbol : Symbol.t
  ; name : string
  ; currency : string
  ; isin : string option
  ; raw : Yojson.Safe.t
  }

type account_summary =
  { account_id : int64
  ; total_value : money
  ; available_cash : money
  ; invested_value : money
  ; raw : Yojson.Safe.t
  }

type position =
  { instrument : instrument
  ; quantity : decimal
  ; current_price : money
  ; average_price_paid : money
  ; raw : Yojson.Safe.t
  }

type order =
  { order_id : int64
  ; symbol : Symbol.t
  ; side : Side.t
  ; status : string
  ; created_at : Time_ns.t
  ; quantity : decimal option
  ; value : money option
  ; raw : Yojson.Safe.t
  }

type fill =
  { fill_id : int64
  ; order_id : int64
  ; symbol : Symbol.t
  ; side : Side.t
  ; filled_at : Time_ns.t
  ; quantity : decimal
  ; price : money
  ; raw : Yojson.Safe.t
  }

type dividend =
  { reference : string
  ; symbol : Symbol.t
  ; paid_on : Time_ns.t
  ; quantity : decimal
  ; amount : money
  ; raw : Yojson.Safe.t
  }

type transaction =
  { reference : string
  ; kind : string
  ; occurred_at : Time_ns.t
  ; amount : money
  ; raw : Yojson.Safe.t
  }

type report_row =
  { report_id : int64
  ; row_number : int
  ; columns : string String.Map.t
  }

type dataset_kind =
  | Account_summary
  | Instruments
  | Exchanges
  | Positions
  | Pending_orders
  | Historical_orders
  | Dividends
  | Transactions
  | Reports
  | Pies
  | Pending_order_details
  | Pie_details
  | Requested_reports
  | Report_files
  | Report_rows
[@@deriving sexp_of, equal]

type availability =
  | Available
  | Unavailable of
      { http_status : int
      ; reason : string
      }

type dataset =
  { kind : dataset_kind
  ; availability : availability
  ; pages : int
  ; records : Yojson.Safe.t list
  }

type t =
  { environment : string
  ; observed_at : Time_ns.t
  ; summary : account_summary option
  ; instruments : instrument list
  ; positions : position list
  ; pending_orders : order list
  ; historical_orders : order list
  ; fills : fill list
  ; dividends : dividend list
  ; transactions : transaction list
  ; report_rows : report_row list
  ; datasets : dataset list
  }

let bad field =
  Error.raise_s
    [%message "Invalid Trading212 snapshot field" (field : string)]
;;

let field json key =
  match json with
  | `Assoc fields ->
    (match List.Assoc.find fields key ~equal:String.equal with
     | Some value -> value
     | None -> bad key)
  | _ -> bad "object"
;;

let optional_field json key =
  match json with
  | `Assoc fields -> List.Assoc.find fields key ~equal:String.equal
  | _ -> bad "object"
;;

let string = function
  | `String s when not (String.is_empty s) -> s
  | _ -> bad "string"
;;

let list = function `List xs -> xs | _ -> bad "array"
let int = function `Int n -> n | _ -> bad "integer"

let int64 = function
  | `Int n -> Int64.of_int n
  | `Intlit s -> Int64.of_string s
  | _ -> bad "int64"
;;

let decimal json =
  let s =
    match json with
    | `String s | `Intlit s -> s
    | `Int n -> Int.to_string n
    | _ -> bad "exact decimal string (JSON float is not allowed)"
  in
  let unsigned = String.chop_prefix_if_exists s ~prefix:"-" in
  let digits s =
    (not (String.is_empty s)) && String.for_all s ~f:Char.is_digit
  in
  match String.split unsigned ~on:'.' with
  | [ whole ] when digits whole -> s
  | [ whole; fraction ] when digits whole && digits fraction -> s
  | _ -> bad "decimal"
;;

let optional parse = function
  | None | Some `Null -> None
  | Some json -> Some (parse json)
;;

let timestamp json = string json |> Time_ns.of_string_with_utc_offset

let currency json =
  let s = string json in
  if String.length s <> 3 || not (String.for_all s ~f:Char.is_uppercase)
  then bad "currency";
  s
;;

let money ~currency amount = { currency; amount = decimal amount }

let instrument ~metadata raw : instrument =
  { symbol = field raw "ticker" |> string |> Symbol.of_string
  ; name = field raw "name" |> string
  ; currency =
      field raw (if metadata then "currencyCode" else "currency") |> currency
  ; isin = optional string (optional_field raw "isin")
  ; raw
  }
;;

let summary raw : account_summary =
  let currency = field raw "currency" |> currency in
  { account_id = field raw "id" |> int64
  ; total_value = money ~currency (field raw "totalValue")
  ; available_cash =
      money ~currency (field (field raw "cash") "availableToTrade")
  ; invested_value =
      money ~currency (field (field raw "investments") "currentValue")
  ; raw
  }
;;

let position raw : position =
  let instrument = field raw "instrument" |> instrument ~metadata:false in
  { instrument
  ; quantity = field raw "quantity" |> decimal
  ; current_price =
      money ~currency:instrument.currency (field raw "currentPrice")
  ; average_price_paid =
      money ~currency:instrument.currency (field raw "averagePricePaid")
  ; raw
  }
;;

let side raw =
  match field raw "side" |> string with
  | "BUY" -> Side.Buy
  | "SELL" -> Side.Sell
  | _ -> bad "side"
;;

let order raw : order =
  let currency = field raw "currency" |> currency in
  { order_id = field raw "id" |> int64
  ; symbol = field raw "ticker" |> string |> Symbol.of_string
  ; side = side raw
  ; status = field raw "status" |> string
  ; created_at = field raw "createdAt" |> timestamp
  ; quantity = optional decimal (optional_field raw "quantity")
  ; value = optional (money ~currency) (optional_field raw "value")
  ; raw
  }
;;

let fill (order : order) raw : fill =
  let instrument =
    field order.raw "instrument" |> instrument ~metadata:false
  in
  { fill_id = field raw "id" |> int64
  ; order_id = order.order_id
  ; symbol = order.symbol
  ; side = order.side
  ; filled_at = field raw "filledAt" |> timestamp
  ; quantity = field raw "quantity" |> decimal
  ; price = money ~currency:instrument.currency (field raw "price")
  ; raw
  }
;;

let dividend raw : dividend =
  { reference = field raw "reference" |> string
  ; symbol = field raw "ticker" |> string |> Symbol.of_string
  ; paid_on = field raw "paidOn" |> timestamp
  ; quantity = field raw "quantity" |> decimal
  ; amount =
      money ~currency:(field raw "currency" |> currency) (field raw "amount")
  ; raw
  }
;;

let transaction raw : transaction =
  { reference = field raw "reference" |> string
  ; kind = field raw "type" |> string
  ; occurred_at = field raw "dateTime" |> timestamp
  ; amount =
      money ~currency:(field raw "currency" |> currency) (field raw "amount")
  ; raw
  }
;;

let dataset_kind = function
  | "account_summary" -> Account_summary
  | "instruments" -> Instruments
  | "exchanges" -> Exchanges
  | "positions" -> Positions
  | "pending_orders" -> Pending_orders
  | "historical_orders" -> Historical_orders
  | "dividends" -> Dividends
  | "transactions" -> Transactions
  | "reports" -> Reports
  | "pies" -> Pies
  | "pending_orders_details" -> Pending_order_details
  | "pies_details" -> Pie_details
  | "requested_reports" -> Requested_reports
  | "report_files" -> Report_files
  | "report_rows" -> Report_rows
  | _ -> bad "dataset kind"
;;

let dataset raw : dataset =
  let status = field raw "status" |> string in
  let availability =
    if String.equal status "ok"
    then Available
    else
      Unavailable
        { http_status = field raw "http_status" |> int; reason = status }
  in
  let pages = field raw "pages" |> int in
  if pages < 0 then bad "pages";
  { kind = field raw "kind" |> string |> dataset_kind
  ; availability
  ; pages
  ; records = field raw "records" |> list
  }
;;

let report_row raw : report_row =
  let columns =
    match field raw "columns" with
    | `Assoc fields ->
      List.map fields ~f:(fun (name, value) ->
        name, match value with `String s -> s | _ -> bad "CSV string")
      |> String.Map.of_alist_exn
    | _ -> bad "CSV columns"
  in
  let row_number = field raw "rowNumber" |> int in
  if row_number < 2 then bad "CSV row number";
  { report_id = field raw "reportId" |> int64; row_number; columns }
;;

let decode_exn text =
  let json = Yojson.Safe.from_string text in
  if field json "schema_version" |> int <> 1 then bad "schema_version";
  if not (String.equal (field json "provider" |> string) "trading212")
  then bad "provider";
  let environment = field json "environment" |> string in
  if not (List.mem [ "live"; "demo" ] environment ~equal:String.equal)
  then bad "environment";
  let datasets = field json "datasets" |> list |> List.map ~f:dataset in
  let seen = ref [] in
  List.iter datasets ~f:(fun dataset ->
    if List.mem !seen dataset.kind ~equal:equal_dataset_kind
    then bad "duplicate dataset";
    seen := dataset.kind :: !seen);
  let records kind =
    match
      List.find datasets ~f:(fun dataset ->
        equal_dataset_kind dataset.kind kind)
    with
    | None -> bad "missing dataset"
    | Some { records; _ } -> records
  in
  let summary =
    match records Account_summary with
    | [] -> None
    | [ raw ] -> Some (summary raw)
    | _ -> bad "summary count"
  in
  let historical =
    records Historical_orders
    |> List.map ~f:(fun raw ->
      let order = field raw "order" |> order in
      order, optional (fill order) (optional_field raw "fill"))
  in
  let fills =
    List.filter_map historical ~f:snd
    |> List.stable_sort ~compare:(fun (a : fill) b ->
      let by_time = Time_ns.compare a.filled_at b.filled_at in
      if by_time = 0 then Int64.compare a.fill_id b.fill_id else by_time)
  in
  { environment
  ; observed_at = field json "observed_at" |> timestamp
  ; summary
  ; instruments =
      records Instruments |> List.map ~f:(instrument ~metadata:true)
  ; positions = records Positions |> List.map ~f:position
  ; pending_orders = records Pending_orders |> List.map ~f:order
  ; historical_orders =
      List.map historical ~f:fst
      |> List.stable_sort ~compare:(fun (a : order) b ->
        Time_ns.compare a.created_at b.created_at)
  ; fills
  ; dividends =
      records Dividends
      |> List.map ~f:dividend
      |> List.stable_sort ~compare:(fun (a : dividend) b ->
        Time_ns.compare a.paid_on b.paid_on)
  ; transactions =
      records Transactions
      |> List.map ~f:transaction
      |> List.stable_sort ~compare:(fun (a : transaction) b ->
        Time_ns.compare a.occurred_at b.occurred_at)
  ; report_rows = records Report_rows |> List.map ~f:report_row
  ; datasets
  }
;;

let decode text =
  Or_error.try_with (fun () -> decode_exn text)
  |> Or_error.tag ~tag:"Could not load Trading212 account snapshot"
;;

let load path =
  let%bind.Or_error text =
    Or_error.try_with (fun () -> In_channel.read_all path)
  in
  decode text
;;

let iter_fills t ~f = List.iter t.fills ~f
