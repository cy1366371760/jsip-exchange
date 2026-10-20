open! Core
open Jsip_broker_data

let command =
  Command.basic
    ~summary:
      "Load a private Trading212 snapshot into typed JSIP observations"
    (let%map_open.Command path =
       flag "-input" (required string) ~doc:"JSON private account snapshot"
     in
     fun () ->
       let snapshot = Trading212_account.load path |> Or_error.ok_exn in
       List.iter snapshot.datasets ~f:(fun dataset ->
         let status =
           match dataset.availability with
           | Available -> "available"
           | Unavailable { reason; http_status } ->
             sprintf "%s HTTP=%d" reason http_status
         in
         printf
           "%s: %s records=%d pages=%d\n"
           (Sexp.to_string
              (Trading212_account.sexp_of_dataset_kind dataset.kind))
           status
           (List.length dataset.records)
           dataset.pages);
       let consumed = ref 0 in
       Trading212_account.iter_fills snapshot ~f:(fun _fill -> incr consumed);
       printf "Consumed %d typed historical broker fills\n" !consumed)
;;

let () = Command_unix.run command
