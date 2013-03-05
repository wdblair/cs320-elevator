import HW = "contrib/CS320"

staload HW("elevator.sats")

(* 
  Compile with atscc -o elevator elevator.dats -ljansson
*)

#define ATS_DYNLOADFLAG 0

#define nil list_nil
#define :: list_cons

(* 
  Decide where to go next.
*)
fun look_for_request(s: state): (state, command) = let
  val schedule = get_schedule(s)
  val direction = state_direction(s)
  val floor = get_floor(s)
in
  case+ schedule of 
    | nil () => (make_state(Ready(), nil, direction, floor), Nothing)
    | x :: xs =>
      case+ x of
      | NeedElevator(flr', direction) => 
        (make_state(Moving(), xs, direction, floor), MoveToFloor(flr'))
      | GoToFloor(_, flr') => 
        (make_state(Moving(), xs, direction, floor), MoveToFloor(flr'))
end

implement elevator_controller
  (state, event) = let
    val control_state = get_control_state(state)
    val schedule = get_schedule(state)
    val direction = state_direction(state)
    val floor = get_floor(state)
in
  case+ event of
    //Open the doors upon arrival
    | Arrived(new_floor) =>
      (make_state(Waiting(), schedule, direction, new_floor), OpenDoor)
    //Decide where to go next
    | DoorsClosed () => look_for_request(state)
    //Add a request to a list
    | Request(r) => let
      val new_schedule = r :: schedule
      val state = make_state(control_state, new_schedule, direction, floor)
    in 
      case+ control_state of
        | Ready() => look_for_request(state)
        | _ =>> (state, Nothing)
    end
end