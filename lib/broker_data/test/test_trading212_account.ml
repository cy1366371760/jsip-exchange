open! Core
open Jsip_broker_data
module Account = Trading212_account

let fixture = In_channel.read_all "fixtures/trading212_snapshot.json"

let%expect_test
    "partial report preserves valid rows and marks incompleteness"
  =
  let text =
    String.substr_replace_all
      fixture
      ~pattern:"\"kind\":\"report_rows\",\"status\":\"ok\""
      ~with_:"\"kind\":\"report_rows\",\"status\":\"partial\""
  in
  let t = Account.decode text |> Or_error.ok_exn in
  printf "valid rows=%d\n" (List.length t.report_rows);
  let dataset =
    List.find_exn t.datasets ~f:(fun d ->
      Account.equal_dataset_kind d.kind Report_rows)
  in
  (match dataset.availability with
   | Available -> print_endline "unexpected complete"
   | Unavailable { reason; _ } -> printf "status=%s\n" reason);
  [%expect
    {|
    valid rows=1
    status=partial
    |}]
;;

let%expect_test "exact decimals, currencies and value orders survive loading"
  =
  let t = Account.decode fixture |> Or_error.ok_exn in
  let summary = Option.value_exn t.summary in
  printf
    "total=%s %s\n"
    (Account.decimal_to_string summary.total_value.amount)
    summary.total_value.currency;
  let position = List.hd_exn t.positions in
  printf
    "position=%s price=%s %s\n"
    (Account.decimal_to_string position.quantity)
    (Account.decimal_to_string position.current_price.amount)
    position.current_price.currency;
  let value_order = List.last_exn t.historical_orders in
  printf
    "value_order_quantity_missing=%b\n"
    (Option.is_none value_order.quantity);
  let metadata_retained =
    match (List.hd_exn t.instruments).raw with
    | `Assoc fields ->
      List.Assoc.mem fields "extraMetadata" ~equal:String.equal
    | _ -> false
  in
  printf "extra_metadata_retained=%b\n" metadata_retained;
  let row = List.hd_exn t.report_rows in
  printf "CSV quantity=%s\n" (Map.find_exn row.columns "No. of shares");
  [%expect
    {|
    total=100.000000000000000001 GBP
    position=0.1234567890123456789 price=123.456789 GBX
    value_order_quantity_missing=true
    extra_metadata_retained=true
    CSV quantity=0.123456789
    |}]
;;

let%expect_test
    "personal fills replay chronologically without submitting orders"
  =
  let t = Account.decode fixture |> Or_error.ok_exn in
  let run () =
    let ids = ref [] in
    Account.iter_fills t ~f:(fun fill -> ids := fill.fill_id :: !ids);
    List.rev !ids
  in
  print_s [%sexp (run () : int64 list)];
  print_s [%sexp (run () : int64 list)];
  let pie =
    List.find_exn t.datasets ~f:(fun d ->
      Account.equal_dataset_kind d.kind Pies)
  in
  (match pie.availability with
   | Available -> print_endline "unexpected available"
   | Unavailable { http_status; reason } ->
     printf "pies=%s HTTP=%d\n" reason http_status);
  [%expect
    {|
    (201 202)
    (201 202)
    pies=gone HTTP=410
    |}]
;;

let%expect_test
    "bad schema, binary float, timestamp and missing datasets fail"
  =
  List.iter
    [ ( "schema"
      , String.substr_replace_all
          fixture
          ~pattern:"\"schema_version\": 1"
          ~with_:"\"schema_version\": 2" )
    ; ( "float"
      , String.substr_replace_all
          fixture
          ~pattern:"\"192.123456789\""
          ~with_:"192.123456789" )
    ; ( "timestamp"
      , String.substr_replace_all
          fixture
          ~pattern:"2026-01-03T10:00:00Z"
          ~with_:"bad-time" )
    ; ( "decimal"
      , String.substr_replace_all
          fixture
          ~pattern:"\"192.123456789\""
          ~with_:"\"NaN\"" )
    ; ( "missing dataset"
      , String.substr_replace_all
          fixture
          ~pattern:"\"kind\":\"positions\""
          ~with_:"\"kind\":\"unknown\"" )
    ]
    ~f:(fun (name, text) ->
      printf
        "%s rejected=%b\n"
        name
        (Or_error.is_error (Account.decode text)));
  [%expect
    {|
    schema rejected=true
    float rejected=true
    timestamp rejected=true
    decimal rejected=true
    missing dataset rejected=true
    |}]
;;
