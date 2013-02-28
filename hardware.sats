staload "elevator.sats"
staload "passenger.sats"

(* ****** ****** *)

fun arrive(_: passenger): void

fun board(_: floor): List(request)

fun leave(_: floor): void

(* ****** ****** *)