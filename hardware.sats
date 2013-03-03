staload "elevator.sats"
staload "passenger.sats"

(* ****** ****** *)

fun arrive(_: passenger): void

fun board(_: floor, _: direction): List(request)

fun leave(_: floor): void

(* ****** ****** *)