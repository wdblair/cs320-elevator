import HW = "contrib/CS320"

staload HW("elevator.sats")

(* 
  Compile with atscc -o elevator elevator.dats -ljansson
*)

#define ATS_DYNLOADFLAG 0

#define nil list_nil
#define :: list_cons

fun look_for_request(s: state): (state, Option(command)) = let
  val schedule = get_schedule(s)
  val direction = state_direction(s)
  val floor = get_floor(s)
in
  case+ schedule of 
    | nil () => (make_state(Ready(), nil, direction, floor), None)
    | x :: xs =>
      case+ x of
      | NeedElevator(flr', direction) => 
        (make_state(Moving(), xs, direction, floor), Some(MoveToFloor(flr')))
      | GoToFloor(_, flr') => 
        (make_state(Moving(), xs, direction, floor), Some(MoveToFloor(flr')))
end

implement elevator_controller
  (state, opt) =
    case+ opt of 
     | None () => (state, None) where {
        val () = println! "No Event!"
     }
     | Some (event) =>
      case+ event of
        //Open the doors upon arrival
        | Arrived(flr) => let
          val schedule = get_schedule(state)
          val dir = state_direction(state)
        in
          (make_state(Waiting(), schedule, dir, flr), Some(OpenDoor))
        end
        //Decide where to go next
        | DoorsClosed () => look_for_request(state)
        //Put requests in a list
        | Request(r) => let
          val control_state = get_control_state(state)
          val schedule' = list_cons(r, get_schedule(state))
          val direction = state_direction(state)
          val floor = get_floor(state)
          val state = make_state(control_state, schedule', direction, floor)
        in 
          case+ get_control_state(state) of
            | Ready() => look_for_request(state)
            | _ =>> (state, None)
        end