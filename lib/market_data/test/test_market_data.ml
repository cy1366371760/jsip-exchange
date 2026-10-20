open! Core
open Jsip_types
open Jsip_market_data

let fixture = In_channel.read_all "fixtures/tushare_daily.json"
let decode_fixture () = Tushare_daily.decode fixture |> Or_error.ok_exn

let%expect_test
    "Python CSV contract loads the same JSIP bars as Tushare JSON"
  =
  let bars =
    Historical_csv.load "fixtures/historical_bars.csv" |> Or_error.ok_exn
  in
  [%test_result: bool]
    (List.equal Historical_bar.equal bars (decode_fixture ()))
    ~expect:true;
  Historical_replay.iter (List.rev bars) ~f:(fun bar ->
    print_endline (Historical_bar.to_string bar));
  [%expect
    {|
    000001.SZ 2024-01-02 open=9.09 high=9.22 low=9.05 close=9.21 volume=52627158 shares
    000001.SZ 2024-01-03 open=9.19 high=9.33 low=9.15 close=9.20 volume=73361027 shares
    000001.SZ 2024-01-04 open=9.19 high=9.20 low=9.02 close=9.09 volume=83737449 shares
    000001.SZ 2024-01-05 open=9.17 high=9.19 low=9.05 close=9.06 volume=66723129 shares
    000001.SZ 2024-01-08 open=9.10 high=9.10 low=8.95 close=9.00 volume=48165852 shares
    |}]
;;

let%expect_test "CSV rejects malformed histories before any consumer runs" =
  let header =
    "symbol,date,open_cents,high_cents,low_cents,close_cents,volume_shares\n"
  in
  let row = "000001.SZ,2024-01-02,909,922,905,921,12345\n" in
  List.iter
    [ "schema", "bad-header\n" ^ row
    ; "row width", header ^ "000001.SZ,2024-01-02\n"
    ; "date", header ^ "000001.SZ,2024-02-30,909,922,905,921,1\n"
    ; "decimal price", header ^ "000001.SZ,2024-01-02,9.09,922,905,921,1\n"
    ; ( "overflow"
      , header ^ "000001.SZ,2024-01-02,9223372036854775807,922,905,921,1\n" )
    ; "OHLC", header ^ "000001.SZ,2024-01-02,909,900,905,921,1\n"
    ; "negative volume", header ^ "000001.SZ,2024-01-02,909,922,905,921,-1\n"
    ; "duplicate", header ^ row ^ row
    ; "symbol", header ^ "bad,2024-01-02,909,922,905,921,1\n"
    ]
    ~f:(fun (name, text) ->
      printf "%s: %b\n" name (Or_error.is_error (Historical_csv.decode text)));
  [%test_result: int]
    (Historical_csv.decode header |> Or_error.ok_exn |> List.length)
    ~expect:0;
  [%expect
    {|
    schema: true
    row width: true
    date: true
    decimal price: true
    overflow: true
    OHLC: true
    negative volume: true
    duplicate: true
    symbol: true
    |}]
;;

let%expect_test "daily fixture decodes to chronological internal bars" =
  decode_fixture ()
  |> List.iter ~f:(fun bar -> print_endline (Historical_bar.to_string bar));
  [%expect
    {|
    000001.SZ 2024-01-02 open=9.09 high=9.22 low=9.05 close=9.21 volume=52627158 shares
    000001.SZ 2024-01-03 open=9.19 high=9.33 low=9.15 close=9.20 volume=73361027 shares
    000001.SZ 2024-01-04 open=9.19 high=9.20 low=9.02 close=9.09 volume=83737449 shares
    000001.SZ 2024-01-05 open=9.17 high=9.19 low=9.05 close=9.06 volume=66723129 shares
    000001.SZ 2024-01-08 open=9.10 high=9.10 low=8.95 close=9.00 volume=48165852 shares
    |}]
;;

let%expect_test "symbol, date, price, and volume conversions are explicit" =
  let first = List.hd_exn (decode_fixture ()) in
  print_s
    [%message
      ""
        ~symbol:(Symbol.to_string first.symbol : string)
        ~date:(Date.to_string first.date : string)
        ~open_cents:(Price.to_int_cents first.open_ : int)
        ~close_cents:(Price.to_int_cents first.close : int)
        ~volume_shares:(first.volume_shares : int64)];
  [%expect
    {|
    ((symbol 000001.SZ) (date 2024-01-02) (open_cents 909) (close_cents 921)
     (volume_shares 52627158))
    |}]
;;

let%expect_test "field names, rather than fixed positions, select values" =
  let reordered =
    {|
      {
        "code": 0,
        "msg": null,
        "data": {
          "fields": ["vol", "close", "ts_code", "low", "trade_date", "open", "high"],
          "items": [[123.45, 10.03, "600000.SH", 9.99, "20240201", 10.01, 10.08]]
        }
      }
    |}
  in
  Tushare_daily.decode reordered
  |> Or_error.ok_exn
  |> List.iter ~f:(fun bar -> print_endline (Historical_bar.to_string bar));
  [%expect
    {|
    600000.SH 2024-02-01 open=10.01 high=10.08 low=9.99 close=10.03 volume=12345 shares
    |}]
;;

let print_error_case name json =
  let outcome =
    match Tushare_daily.decode json with
    | Ok _ -> "unexpected success"
    | Error _ -> "error"
  in
  printf "%s: %s\n" name outcome
;;

let error_mentions json text =
  match Tushare_daily.decode json with
  | Ok _ -> false
  | Error error ->
    String.is_substring (Error.to_string_hum error) ~substring:text
;;

let%expect_test "malformed data, API errors, and lossy prices are rejected" =
  print_error_case "invalid JSON" "{";
  print_error_case
    "missing field"
    {|
      {
        "code": 0,
        "msg": null,
        "data": {
          "fields": ["ts_code", "trade_date", "open", "high", "low", "close"],
          "items": []
        }
      }
    |};
  print_error_case
    "non-zero code"
    {|{"code": 2002, "msg": "permission denied", "data": null}|};
  [%test_result: bool]
    (error_mentions
       {|{"code": 2002, "msg": "permission denied", "data": null}|}
       "Tushare daily API error")
    ~expect:true;
  print_error_case
    "sub-cent price"
    {|
      {
        "code": 0,
        "msg": null,
        "data": {
          "fields": ["ts_code", "trade_date", "open", "high", "low", "close", "vol"],
          "items": [["000001.SZ", "20240102", 9.091, 9.22, 9.05, 9.21, 1]]
        }
      }
    |};
  [%expect
    {|
    invalid JSON: error
    missing field: error
    non-zero code: error
    sub-cent price: error
    |}]
;;

let replay_dates bars =
  let dates = ref [] in
  Historical_replay.iter bars ~f:(fun bar ->
    dates := Date.to_string bar.date :: !dates);
  List.rev !dates
;;

let%expect_test "replay is chronological and deterministic" =
  let reverse_chronological = List.rev (decode_fixture ()) in
  let first = replay_dates reverse_chronological in
  let second = replay_dates reverse_chronological in
  print_s [%message "" (first : string list) (second : string list)];
  [%expect
    {|
    ((first (2024-01-02 2024-01-03 2024-01-04 2024-01-05 2024-01-08))
     (second (2024-01-02 2024-01-03 2024-01-04 2024-01-05 2024-01-08)))
    |}]
;;
