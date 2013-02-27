(* ****** ****** *)

typedef floor = int

datatype direction = 
  | Up of ()
  | Down of ()

datatype control_state =
  | Ready  of ()
  | Waiting of ()
  | Moving of ()
  
datatype command = 
  | MoveToFloor of (int)
  | OpenDoor of ()

datatype request =
  | NeedElevator of (floor, direction)
  | GoToFloor of (floor)

datatype event = 
  | Arrived of (floor)
  | DoorsClosed of ()
  | Request of (request)
  
typedef schedule = List(request)
typedef events = List(event)

fun elevator_loop (
  _: control_state, _: schedule, _: direction, _: events
): (control_state, schedule, direction, Option(command))

(* ****** ****** *)