(* ****** ****** *)

(* 
  floor - A number between 1 and 10
*)
typedef floor = int

(*
  Whenever an elevator stops at a floor, its direction 
  is displayed to potential passengers. Passengers will 
  only board an elevator if the direction is the same
  in which they want to travel.
*)
datatype direction = 
  | Up of ()
  | Down of ()

fun eq_direction_direction(_: direction, _: direction):<> bool

overload = with eq_direction_direction

(*
  At any point the elevator will be in 
  one of these three states.
  
  Ready - The elevator is ready to go to the
    next floor in its schedule.
    
  Waiting - The elevator has nothing to do. Either
    there are no requests or it's waiting for the 
    doors to close.
    
  Moving - The elevator has previously issued
  a move command and is now waiting 
*)
datatype control_state =
  | Ready  of ()
  | Waiting of ()
  | Moving of ()

(*
  An elevator controller can issue two commands. One
  tells the elevator to go to a new floor. The other 
  opens the elevator door.
*)
datatype command = 
  | MoveToFloor of (int)
  | OpenDoor of ()

(*
  An elevator needs to service two different customers,
  prospective passengers that need an elevator and 
  passengers inside the elevator.

  NeedElevator - A customer needs an elevator going
  in direction d at floor f.
  
  GoToFloor - A customer inside the elevator wants
  to go to floor f.
*)
datatype request =
  | NeedElevator of (floor, direction)
  | GoToFloor of (floor)
  
(*
  An elevator controller receives input from the 
  outside world through external events.
  
  Whenever an event occcurs, your controller is called 
  to decide what to do next. For example, the Arrived event
  always occurs sometime after our controller returns
  a MoveToFloor command. 
  
  Requests don't necessarily come in response to commands.
  Throughout the simulation passengers will arrive at
  random floors in need of elevators. After you open the 
  doors at a specific floor, passengers will enter and 
  enter a request for where they want to go.
  
  It is never the case that you will want to ignore one 
  of these events, otherwise you could deadlock or ignore 
  passengers.
*)
datatype event =
  | Arrived of (floor)
  | DoorsClosed of ()
  | Request of (request)
  
typedef schedule = List(request)
typedef events = List(event)

(* 
  The goal of the elevator controller is to implement
  a simple SCAN scheduler to move passengers to their
  destinations.
  
  Given a set of requests, a SCAN scheduler chooses a 
  direction and only services requests in increasing order
  along its current direction. When no more requests remain,
  it switches direction and repeats the process.
  
  Your controller's state is revealed through arguments
  passed to this function. The control_state, schedule,
  and direction variables you return will always persist 
  to be the arguments of the next call to elevator_controller. 
  The events parameter is the simulator's way to inform you of
  what's going on outside your controller, and the optional
  command allows you to move your elevator and open the door.
*)
fun elevator_controller (
  _: control_state, _: schedule, _: direction, _: floor,  _: events
): (control_state, schedule, direction, floor,  Option(command))