%{#
#include "elevator_passenger.cats"
%}

staload "simulator.sats"
staload "elevator.sats"

typedef id = int

abst@ype passenger = @{
  id= int
}

fun make_passenger (
  start: int, direction: direction, floor: floor
):<> passenger

fun new_id (): int  //get the next id  

fun get_id (
  p: passenger
):<> id

fun get_floor (
  p: passenger
):<> floor

fun get_direction (
  p: passenger
):<> direction

fun set_destination (
  p: passenger, f:floor
):<> void

fun get_destination (
  p: passenger
):<> int

fun compare_passenger_passenger(p1: passenger, p2: passenger):<> Sgn

overload compare with compare_passenger_passenger

fun eq_passenger_passenger(p1: passenger, p2: passenger):<> bool

overload = with eq_passenger_passenger
