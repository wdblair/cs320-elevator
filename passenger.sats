staload "simulator.sats"
staload "elevator.sats"

abst@ype passenger = @{
  id= int,
  start= int,
  destination= int,
  direction= direction,
  arrived= double,
  exited= double
}

fun make_passenger (
  id: int, start: double, direction: direction
): passenger





