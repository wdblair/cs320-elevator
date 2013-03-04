import HW = "contrib/CS320"

staload HW("elevator.sats")

(* 
  Compile with atscc -o elevator elevator.dats -ljansson
*)

#define ATS_DYNLOADFLAG 0

implement elevator_controller 
  (control_state, schedule, dir, flr, event) = let
   val () =  case+ event of
              | None () => println! "No Event!"
              | Some (event) =>
                case+ event of 
                  | Arrived (flr) => println! "Arrived at floor"
                  | DoorsClosed () => println! "Doors closed!"
                  | Request(r) => 
                    (case+ r of 
                      | NeedElevator (flr, direction) => println!("Need an Elevator on floor ", flr)
                      | GoToFloor (flr) => println!("Move the Elevator to floor ", flr)
                    )
in
  (control_state, schedule, dir, flr, None)
end