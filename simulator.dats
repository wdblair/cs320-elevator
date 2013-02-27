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

typedef state = (control_state, schedule, direction, floor)

#define :: list_cons
#define nil list_nil

implement elevator_simulation () = let
  val opt = json_from_string(service_requests)
  fun json_array_to_list(
    arr: json
  ): List_vt(json) = let
    val size = array_size(arr)
    fun loop(
      arr: json, i: int, res: List_vt(json)
    ):<cloref1>  List_vt(json) =
        if i = size then res where {
          val _ = json_free(arr)
        }
        else let
          val obj = array_get(arr, i)
        in
          loop(arr, i + 1, list_vt_cons(obj, res))
        end
  in
    loop(arr, 0, list_vt_nil())
  end
in
  case+ opt of
    | ~None_vt() => exit(1) where {
      val _ = println! "Cannot read requests."
    }
    | ~Some_vt(need_service) => {
      val passengers = json_array_to_list(need_service)
      val output = json_array()
      val start = (Ready(), nil, Up(), 1)
      fun loop (people: List_vt(json), record: !json,
        time: double, st: state 
      ): void = let
        fun get_new_arrivals(
          xs: List_vt(json)
        ):<cloref1> (events, List_vt(json)) = let
          fun loop(
            xs: List_vt(json), res0: events
          ):<cloref1> (events, List_vt(json)) =
            case+ xs of 
              | list_vt_nil () => let
                  prval () = fold@ xs
                in (res0, xs) end
              | ~list_vt_cons(p, ps) => let
                val arrive = double(object_get_exn(p, "time"))
              in
                if time < arrive then
                  (res0, list_vt_cons(p, ps)) //fold@ wasn't working...
                else let
                  val floor = int(object_get_exn(p, "flr"))
                  val dir = 
                    case+ string(object_get_exn(p, "dir")) of
                      | "u" => Up()                  
                      | "d" => Down()
                      | _ =>> Down()
                  val req = NeedElevator(floor, dir)
                  val evnt = Request(req)
                  val _ = json_free(p)
                in
                  loop(ps, evnt :: res0)
                end
              end
        in loop(xs, nil) end
        //
        //Generate new arrivals.
        //
        val (arrived, togo) = get_new_arrivals(people)
        //
        //Get the new state
        //
        val (control, sched, dir, floor, cmd) =
          elevator_controller(st.0, st.1, st.2, st.3, arrived)
        val timenxt =
          case+ cmd of
            | Some(cmd) => 
              (case+ cmd of
                | MoveToFloor(target) => time + abs(floor - target)
                | _ =>> time + 2.0)
            | None() => time + 1.0
      in
        loop(togo, record, timenxt, (control, sched, dir, floor))
      end
      val _ = loop(passengers, output , 0.0, start)
      val _ = save_to_file(output, "output.json")
      val _ = json_free(output)
    }
end

(* ****** ****** *)