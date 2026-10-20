open! Core
open Jsip_market_data

(* A minimal historical market-data consumer. Future research consumers use
   this same callback boundary, independently of the simulated exchange. *)
let command =
  Command.basic
    ~summary:"Load raw A-share history and replay typed JSIP market bars"
    (let%map_open.Command path =
       flag "-input" (required string) ~doc:"CSV historical export to replay"
     in
     fun () ->
       let bars = Historical_csv.load path |> Or_error.ok_exn in
       Historical_replay.iter bars ~f:(fun bar ->
         print_endline (Historical_bar.to_string bar));
       printf "Replayed %d historical bars\n" (List.length bars))
;;

let () = Command_unix.run command
