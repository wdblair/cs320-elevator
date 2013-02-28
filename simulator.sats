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
  direction: direction, time: double
): void

(* ****** ****** *)