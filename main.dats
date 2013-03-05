(* ****** ***** *)

staload "simulator.sats"
staload "elevator.sats"

(* ****** ***** *)

dynload "simulator.dats"
dynload "hardware.dats"
dynload "passenger.dats"
dynload "data.dats"
dynload "elevator.dats"

(* ****** ***** *)

implement main () = elevator_simulation()