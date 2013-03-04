%{#
#include <stdlib.h>
%}

(* ****** ****** *)

staload "elevator.sats"

fun seed (): void

fun random_number (min:int, max: int): int

fun elevator_simulation (): void

val service_requests : string

fun publish_event (
  tag: string, id: int, flr: int,
  direction: Option(direction)
): void

(* ****** ***** *)

(*
  Increments the internal time in the
  simulator by t seconds.
*)
fun wait (t: int): void

fun time(): int

(* ****** ****** *)