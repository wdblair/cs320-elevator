staload "simulator.sats"
staload "elevator.sats"

typedef id = int

abst@ype passenger = @{
  id= id,
  start= floor,
  destination= floor,
  direction= direction,
  arrived= double,
  exited= double
}

fun make_passenger (
  id: int, start: double, direction: direction
):<> passenger

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
