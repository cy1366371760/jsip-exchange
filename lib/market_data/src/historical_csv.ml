open! Core
open Jsip_types

let header =
  "symbol,date,open_cents,high_cents,low_cents,close_cents,volume_shares"
;;

let integer_exn text ~field =
  if String.is_empty text || not (String.for_all text ~f:Char.is_digit)
  then Error.raise_s [%message "Expected unsigned integer" (field : string)];
  Int64.of_string text
;;

let symbol_exn text =
  match String.split text ~on:'.' with
  | [ code; exchange ]
    when String.length code = 6
         && String.for_all code ~f:Char.is_digit
         && List.mem [ "SH"; "SZ"; "BJ" ] exchange ~equal:String.equal ->
    Symbol.of_string text
  | _ -> Error.raise_s [%message "Invalid A-share symbol" (text : string)]
;;

let row_exn text =
  match String.split text ~on:',' with
  | [ symbol; date; open_; high; low; close; volume ] ->
    let parsed_date = Date.of_string date in
    if not (String.equal date (Date.to_string parsed_date))
    then Error.raise_s [%message "Expected YYYY-MM-DD date" (date : string)];
    let price field text =
      integer_exn text ~field |> Int64.to_int_exn |> Price.of_int_cents
    in
    Historical_bar.create
      ~symbol:(symbol_exn symbol)
      ~date:parsed_date
      ~open_:(price "open_cents" open_)
      ~high:(price "high_cents" high)
      ~low:(price "low_cents" low)
      ~close:(price "close_cents" close)
      ~volume_shares:(integer_exn volume ~field:"volume_shares")
    |> Or_error.ok_exn
  | _ -> Error.raise_s [%message "Expected seven CSV fields"]
;;

let decode text =
  match String.split_lines text with
  | [] -> Or_error.error_string "Historical CSV: missing header"
  | actual_header :: rows ->
    if not (String.equal actual_header header)
    then Or_error.error_string "Historical CSV: unsupported header/schema"
    else (
      let%bind.Or_error bars =
        List.mapi rows ~f:(fun index row ->
          Or_error.try_with (fun () -> row_exn row)
          |> Or_error.tag ~tag:(sprintf "Historical CSV line %d" (index + 2)))
        |> Or_error.combine_errors
      in
      let bars =
        List.stable_sort bars ~compare:Historical_bar.compare_chronologically
      in
      match
        List.find_consecutive_duplicate bars ~equal:(fun left right ->
          Historical_bar.compare_chronologically left right = 0)
      with
      | Some (left, _) ->
        Or_error.error_s
          [%message
            "Historical CSV: duplicate symbol/date"
              (left.symbol : Symbol.t)
              (left.date : Date.t)]
      | None -> Ok bars)
;;

let load path =
  let%bind.Or_error text =
    Or_error.try_with (fun () -> In_channel.read_all path)
    |> Or_error.tag ~tag:(sprintf "Could not read historical CSV %s" path)
  in
  decode text
;;
