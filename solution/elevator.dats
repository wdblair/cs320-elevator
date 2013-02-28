import HW = "contrib/CS320"

staload HW("elevator.sats")

(* 
  Compile with atscc -o elevator elevator.dats -ljansson
*)

#define ATS_DYNLOADFLAG 0

implement elevator_controller 
  (control_state, schedule, dir, flr, events) = let
  //Print out all events here...
  fun loop(lst: events): void =
    case+ lst of
      | list_nil () => ()
      | list_cons (x, xs) => let
        val () = case+ x of
          | Request (req) =>
            (case+ req of
              | NeedElevator(dest, dir) =>
                println!(dest)
              | _ =>> ())
          | _ =>> ()
       in loop(xs) end
  val _ = loop(events)
in
  (control_state, schedule, dir, flr, None)
end