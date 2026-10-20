(** Loads Trading 212 account observations exported by Python ingestion.
    Brokerage fills are historical facts, never simulated exchange orders.
    All source fields remain available in [raw] and [datasets]. *)

open! Core
open Jsip_types

(** A validated exact decimal, including fractional shares and sub-cent prices.
    No rounding, currency conversion or float arithmetic occurs in this loader.
*)
type decimal = private string

val decimal_to_string : decimal -> string

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

(** Report headers retain their units. No numbers or dates are guessed from CSV.
*)
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

type t = private
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

(** Loads schema 1, validates numbers/dates and retains unavailable sections.
    Historical records are sorted by timestamp. No credentials are required.
*)
val decode : string -> t Or_error.t

val load : string -> t Or_error.t

(** Delivers fills in chronological order to a read-only research callback.
*)
val iter_fills : t -> f:(fill -> unit) -> unit
