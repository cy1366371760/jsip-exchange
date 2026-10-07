open! Core
open Jsip_types

let malformed message =
  Error.raise_s
    [%message "Malformed Tushare daily response" (message : string)]
;;

let as_object ~at = function
  | `Assoc fields -> fields
  | _ -> malformed (at ^ " must be an object")
;;

let as_list ~at = function
  | `List values -> values
  | _ -> malformed (at ^ " must be an array")
;;

let member_exn fields name =
  match List.Assoc.find fields name ~equal:String.equal with
  | Some value -> value
  | None -> malformed (sprintf "missing %S" name)
;;

let as_string ~at = function
  | `Stringlit literal ->
    (match Yojson.Safe.from_string literal with
     | `String value -> value
     | _ -> malformed (at ^ " must be a string"))
  | _ -> malformed (at ^ " must be a string")
;;

let as_code = function
  | `Intlit text ->
    (match Int.of_string text with
     | code -> code
     | exception _ -> malformed "code must be an integer")
  | _ -> malformed "code must be an integer"
;;

let numeric_lexeme ~field = function
  | `Intlit text | `Floatlit text -> text
  | _ -> malformed (sprintf "field %S must be a JSON number" field)
;;

let all_digits text =
  (not (String.is_empty text)) && String.for_all text ~f:Char.is_digit
;;

(* Parse a plain JSON decimal directly to hundredths. This keeps provider
   floats out of the domain and lets us reject precision loss explicitly. *)
let hundredths_of_decimal ~field text =
  let negative, unsigned =
    match String.chop_prefix text ~prefix:"-" with
    | Some unsigned -> true, unsigned
    | None -> false, text
  in
  let whole, fraction =
    match String.split unsigned ~on:'.' with
    | [ whole ] when all_digits whole -> whole, "00"
    | [ whole; fraction ] when all_digits whole && all_digits fraction ->
      if String.length fraction <= 2
      then whole, fraction ^ String.make (2 - String.length fraction) '0'
      else (
        let hundredths = String.prefix fraction 2 in
        let remainder = String.drop_prefix fraction 2 in
        if String.for_all remainder ~f:(Char.equal '0')
        then whole, hundredths
        else
          malformed
            (sprintf
               "field %S value %S is not exactly representable in hundredths"
               field
               text))
    | _ ->
      malformed
        (sprintf
           "field %S value %S is not a plain decimal number"
           field
           text)
  in
  let scaled = (if negative then "-" else "") ^ whole ^ fraction in
  match Int64.of_string scaled with
  | value -> value
  | exception _ ->
    malformed (sprintf "field %S is outside int64 range" field)
;;

let price_of_json ~field json =
  let cents = numeric_lexeme ~field json |> hundredths_of_decimal ~field in
  match Int64.to_int_exn cents with
  | cents -> Price.of_int_cents cents
  | exception _ -> malformed (sprintf "field %S cannot fit Price.t" field)
;;

let volume_shares_of_json json =
  (* Tushare reports [vol] in lots; for A-shares one lot is 100 shares. *)
  numeric_lexeme ~field:"vol" json |> hundredths_of_decimal ~field:"vol"
;;

let symbol_of_json json =
  let text = as_string ~at:"ts_code" json in
  match String.split text ~on:'.' with
  | [ local_code; exchange ]
    when String.length local_code = 6
         && String.for_all local_code ~f:Char.is_digit
         && List.mem [ "SH"; "SZ"; "BJ" ] exchange ~equal:String.equal ->
    Symbol.of_string text
  | _ ->
    malformed
      (sprintf
         "ts_code %S must be six digits followed by .SH, .SZ, or .BJ"
         text)
;;

let date_of_json json =
  let text = as_string ~at:"trade_date" json in
  if String.length text <> 8 || not (String.for_all text ~f:Char.is_digit)
  then malformed (sprintf "trade_date %S must have YYYYMMDD form" text);
  match
    Date.create_exn
      ~y:(Int.of_string (String.sub text ~pos:0 ~len:4))
      ~m:(Month.of_int_exn (Int.of_string (String.sub text ~pos:4 ~len:2)))
      ~d:(Int.of_string (String.sub text ~pos:6 ~len:2))
  with
  | date -> date
  | exception _ -> malformed (sprintf "invalid trade_date %S" text)
;;

let field_indexes fields_json =
  List.foldi fields_json ~init:String.Map.empty ~f:(fun index indexes json ->
    let field = as_string ~at:"data.fields[]" json in
    if Map.mem indexes field
    then malformed (sprintf "duplicate field name %S" field)
    else Map.set indexes ~key:field ~data:index)
;;

let required_index indexes field =
  match Map.find indexes field with
  | Some index -> index
  | None ->
    malformed (sprintf "data.fields is missing required field %S" field)
;;

let parse_item indexes json =
  let row = as_list ~at:"data.items[]" json in
  let field name =
    match List.nth row (required_index indexes name) with
    | Some value -> value
    | None -> malformed (sprintf "item has no value for field %S" name)
  in
  Historical_bar.create
    ~symbol:(symbol_of_json (field "ts_code"))
    ~date:(date_of_json (field "trade_date"))
    ~open_:(price_of_json ~field:"open" (field "open"))
    ~high:(price_of_json ~field:"high" (field "high"))
    ~low:(price_of_json ~field:"low" (field "low"))
    ~close:(price_of_json ~field:"close" (field "close"))
    ~volume_shares:(volume_shares_of_json (field "vol"))
  |> Or_error.ok_exn
;;

let response_message fields =
  match member_exn fields "msg" with
  | `Null -> ""
  | json -> as_string ~at:"msg" json
;;

let decode_exn text =
  let fields = Yojson.Raw.from_string text |> as_object ~at:"response" in
  let code = member_exn fields "code" |> as_code in
  let message = response_message fields in
  if code <> 0
  then
    Error.raise_s
      [%message "Tushare daily API error" (code : int) (message : string)];
  let data = member_exn fields "data" |> as_object ~at:"data" in
  let indexes =
    member_exn data "fields" |> as_list ~at:"data.fields" |> field_indexes
  in
  List.iter
    [ "ts_code"; "trade_date"; "open"; "high"; "low"; "close"; "vol" ]
    ~f:(fun field -> ignore (required_index indexes field : int));
  member_exn data "items"
  |> as_list ~at:"data.items"
  |> List.map ~f:(parse_item indexes)
  |> List.stable_sort ~compare:Historical_bar.compare_chronologically
;;

let decode text =
  Or_error.try_with (fun () -> decode_exn text)
  |> Or_error.tag ~tag:"Could not decode Tushare daily response"
;;
