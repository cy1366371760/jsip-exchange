open! Core

let iter bars ~f =
  List.stable_sort bars ~compare:Historical_bar.compare_chronologically
  |> List.iter ~f
;;
