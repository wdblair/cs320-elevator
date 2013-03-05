import Global = "contrib/global"
import JS = "contrib/json"

staload Global("global.sats")
staload JS("json.sats")

staload "simulator.sats"
staload "elevator.sats"
staload "passenger.sats"
staload "hardware.sats"

staload _ = "prelude/DATS/list.dats"
staload _ = "prelude/DATS/list_vt.dats"

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
  val () = 
    case+ tag of
      | "move" =>   
        object_set(obj, "from", encode(flr))
      | _ =>> ()
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
  val () = !time := !time + (t)
  prval () = global_return(time_lock, pf)
}

implement time () = t where {
  val (pf | time) = global_get(time_lock)
  val t = !time
  prval () = global_return(time_lock, pf)
}

#define :: list_cons
#define nil list_nil

typedef time_event = @(int, event)

implement elevator_simulation () = let
  val opt = json_from_string(service_requests)
  fun json_array_to_events(
    arr: json
  ): List(time_event) = let
    val size = array_size(arr)
    fun loop(
      arr: json, i: int, res: List(time_event)
    ):<cloref1>  List(time_event) =
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
              | _ => Up()
          val _ = json_free(obj)
        in
          loop(arr, i + 1, @(time, Request(NeedElevator(floor, direction))) :: res)
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
      val start = make_state(Ready(), nil, Up(), 1)
      
      fun loop(schedule: List(time_event), controller: state, elevator_floor: &int): void = let
        fn cmp (t1:time_event, t2: time_event, p: !ptr):<> int = compare(t1.0, t2.0)
        //go to the next event
        val sorted_schedule = list_of_list_vt {time_event} (
          list_quicksort<time_event>{ptr}(schedule, cmp, null)
        )
      in
        case+ sorted_schedule of
          | nil () => ()
          | x :: xs => let
            val () =
              if x.0 > time() then
                wait((x.0 - time()))
            val () =
              case+ x.1 of
                //Record new arrivals.
                | Request(r) =>
                  (case+ r of
                    | NeedElevator(floor, direction) => let
                      val p = make_passenger(time(), direction, floor)
                    in
                      arrive(p)
                    end
                    | GoToFloor(id, floor) => publish_event("request", id, floor, None)
                 )
                | Arrived(flr) => {
                  val () = elevator_floor := flr
                  val () = publish_event("arrive", ~1, flr, None)
                }
                | DoorsClosed() => {
                  val () = publish_event("close", ~1, ~1, None)
                }
            val (controller, opt) =
              elevator_controller(controller, Some(x.1))
          in
            case+ opt of
              | None () => loop(xs, controller, elevator_floor)
              | Some (cmd) =>
                  case+ cmd of
                    | MoveToFloor(floor) => let
                      val event = Arrived(floor)
                      val time = time() + (abs(elevator_floor - floor)*1000)
                      val () = publish_event("move", ~1, floor, None)
                     in
                        loop(list_cons(@(time,event), xs), controller, elevator_floor)
                     end
                    | OpenDoor() =>
                      case+ get_control_state(controller) of
                        | Moving() => exit(1) where {
                          val _ = prerrln! "You cannot open the door while moving."
                        }
                        |  _ =>> let
                          val () = publish_event("open", ~1, ~1, Some(state_direction(controller)))
                          val () = leave(elevator_floor)
                          val boarding = board(elevator_floor, state_direction(controller))
                          fun timestamp(schedule: List(request),  i: int, res: List(time_event)): List(time_event) =
                            case+ schedule of
                              | list_nil() => let
                                 val closed = list_cons(@(time()+i*1000, DoorsClosed()), res)
                               in
                                  list_of_list_vt ( 
                                    list_reverse<time_event>(closed)
                                  )
                               end
                              | list_cons(e, es) =>
                                timestamp(es, i+1, list_cons(@(time()+i*1000, Request(e)), res))
                          val requests = timestamp(boarding, 0, list_nil)
                        in
                          loop(list_append(requests,xs), controller, elevator_floor)
                        end
          end
      end
      var floor : int = 1
      val _ = loop(passengers, start, floor)
      val (pf | output) = global_get(output_lock)
      val _ = save_to_file(!output, "output.json")
      prval () = global_return(output_lock, pf)
    }
end

(* ****** ****** *)