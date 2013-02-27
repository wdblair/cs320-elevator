(* ****** ***** *)

staload "simulator.sats"
staload "elevator.sats"

dynload "simulator.dats"
dynload "data.dats"

implement main () = elevator_simulation()