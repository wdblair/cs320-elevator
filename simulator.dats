import Global = "contrib/global"
import JS = "contrib/json"

staload Global("global.sats")
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

local
  var output : json with pfout = json_array()
  var time : int with pftime = 0
  
  viewdef out = json @ output 
  viewdef time = int @ time
  
  
  prval outlock = viewlock_new{out}(pfout)
  prval timelock = viewlock_new{time}(pftime)
in
  val output_lock = @{lock= outlock, p= &output}
  val time_lock = @{lock= timelock, p= &time}
end

implement publish_event(tag, id, flr, direction) = {
  val (pf | time) = global_get(time_lock)
  //
  val obj = json_object()
  val () = object_set(obj, "tag", encode(tag))
  val () = object_set(obj, "id", encode(id))
  val () = object_set(obj, "flr", encode(flr))
  val () = object_set(obj, "time", encode(!time))
  //
  prval () = global_return(time_lock, pf)
  val () =
    case+ direction of
      | None () => ()
      | Some (dir) => {
        val label =
          case+ dir of
          | Up () => "u"
          | Down() => "d"
        val _ = object_set(obj, "dir", encode(label))
      }
  val (pf | output) = global_get(output_lock)
  val () = array_append(!output, obj)
  prval () = global_return(output_lock, pf)
}

implement wait(t) = {
  val (pf | time) = global_get(time_lock)
  val () = !time := !time + t
  prval () = global_return(time_lock, pf)
}

typedef state = (control_state, schedule, direction, floor)

#define :: list_cons
#define nil list_nil

implement elevator_simulation () = let
  val opt = json_from_string(service_requests)
  fun json_array_to_events(
    arr: json
  ): List(@(int, event)) = let
    val size = array_size(arr)
    fun loop(
      arr: json, i: int, res: List(@(int, event))
    ):<cloref1>  List(@(int,event)) =
        if i = size then res where {
          val _ = json_free(arr)
        }
        else let
          val obj = array_get(arr, i)
          val time = double(object_get_exn(obj, "time"))
          val time = int_of_double(time)
          val floor = int(object_get_exn(obj, "flr"))
          val direction = string(object_get_exn(obj, "dir"))
          val direction = 
            case+ direction of  
              | "d" => Down()
              | "u" => Up()
              | _ =>> Up()
          val _ = json_free(obj)
        in
          loop(arr, i + 1, @(time, Request(NeedElevator(floor, direction))):: res)
        end
  in
    loop(arr, 0, nil)
  end
in
  case+ opt of
    | ~None_vt() => exit(1) where {
      val _ = println! "Cannot read requests."
    }
    | ~Some_vt(need_service) => {
      val passengers = json_array_to_events(need_service)
      val output = json_array()
      val start = (Ready(), nil, Up(), 1)
      fun loop (schedule: List(@(int, event)), record: !json, st: state, tooccur: events
      ): void = let
        //
        //Get new events
        //
        fn cmp(
          x: @(int, event), y: @(int, event), z: !ptr
        ):<> int = compare(x.0, y.0)
        val todo = list_of_list_vt{@(int,event)}(
          list_quicksort<@(int, event)>{ptr}(schedule, cmp, null)
        )
      in 
        case+ todo of 
          | nil() => ()
          | next :: schedule => let
            val (control, sched, dir, floor, cmd) =
              elevator_controller(st.0, st.1, st.2, st.3, tooccur)
          in
            loop(schedule, record, (control, sched, dir, floor), list_nil)
          end
      end
      val _ = loop(passengers, output, start, list_nil)
      val _ = save_to_file(output, "output.json")
      val _ = json_free(output)
    }
end

(* ****** ****** *)