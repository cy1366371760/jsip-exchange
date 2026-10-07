(** Historical market-data types, provider adapters, and deterministic replay.

    This library deliberately has no dependency on the order book, matching
    engine, gateway, or bot runtime. *)

module Historical_bar = Historical_bar
module Historical_replay = Historical_replay
module Tushare_daily = Tushare_daily
