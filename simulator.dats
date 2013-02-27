import JS = "contrib/json"

staload JS("json.sats")

staload "simulator.sats"
staload "elevator.sats"

local
  extern
  fun rand(): int = "mac#" 

  extern
  fun srand(seed: uint): void = "mac#"
in
  implement seed() = srand(0x100u)
  
  implement random_number (min, max) = let
    val cr = rand()
    val dist = max - min
    val step = cr mod (dist+1)
  in min + step end
end

fun publish_event (
  js: !json, tag: string, id: int, flr: int, 
  direction: direction, time: double
): void = {
  val obj = json_object()
  val () = object_set(obj, "tag", encode(tag))
  val () = object_set(obj, "id", encode(id))
  val () = object_set(obj, "flr", encode(flr))
  val () = object_set(obj, "time", encode(time))
  val dir = 
    case+ direction of
      | Up() => "u"
      | Down() => "d"
  val () = object_set(obj, "dir", encode(dir))
  val () = array_append(js, obj)
}

typedef state = (control_state, schedule, direction)

#define :: list_cons
#define nil list_nil

implement elevator_simulation () = let
  val opt = json_from_string(service_requests)
in
  case+ opt of
    | ~None_vt() => exit(1) where {
      val _ = println! "Cannot read requests."
    }
    | ~Some_vt(need_service) => {
      val output = json_array()
      val start = (Ready(), nil, Up())
      fun loop ( arrivals: !json, record: !json, 
        time: double, st: state 
      ): void = let
        //Create new events.
        val events = nil
        //Get the new state
        val (control, sched, dir, cmd) =
          elevator_controller(st.0, st.1, st.2, events)
      in
        loop(arrivals, record, time, (control, sched, dir))
      end
      val _ = loop(need_service, output , 0.0, start)
      val _ = save_to_file(output, "output.json")
      val _ = json_free(output)
      val _ = json_free(need_service)
    }
end

(* ****** ****** *)