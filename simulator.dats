import JS = "contrib/json"

staload JS("json.sats")

staload "simulator.sats"
staload "elevator.sats"

local
  macdef RAND_MAX = $extval(int, "RAND_MAX")

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

implement elevator_simulation () = let
  val opt = json_from_string(service_requests)
in
  case+ opt of
    | ~None_vt() => exit(1) where {
      val _ = println! "Cannot read requests."
    }
    | ~Some_vt(need_service) => {
      fun loop (js: !json, time: double): void = let
      in
        loop(js, time)
      end
      val _ = json_free(need_service)
    }
end

(* ****** ****** *)