(** Deterministic replay of provider-independent historical bars. *)

open! Core

(** Calls [f] once per bar in ascending date/symbol order. Equal date/symbol
    pairs retain their input order. No clock, sleeping, or I/O is involved.
*)
val iter : Historical_bar.t list -> f:(Historical_bar.t -> unit) -> unit
