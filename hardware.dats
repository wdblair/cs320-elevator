import Global = "contrib/global"

staload Global("global.sats")

staload "simulator.sats"
staload "elevator.sats"
staload "passenger.sats"

staload "hardware.sats"

staload Map = "libats/SATS/linmap_skiplist.sats"
staload _ = "libats/DATS/linmap_skiplist.dats"
stadef map = $Map.map

staload Set = "libats/SATS/linset_avltree.sats"
staload _ = "libats/DATS/linset_avltree.dats"
stadef set = $Set.set

staload _ = "prelude/SATS/list_vt.sats"

(* ****** ****** *)

//internal state for the elevator

implement $Map.compare_key_key<id>(k1, k2, cmp) =
  if k1 < k2 then ~1 else if k1 > k2 then 1 else 0

implement $Set.compare_elt_elt<passenger>(p1, p2, cmp) = let
  val k1 = get_id(p1)
  val k2 = get_id(p2)
in
  if k1 < k2 then ~1 else if k1 > k2 then 1 else 0
end

fn cmp (x1: id, x2: id):<cloref> Sgn = compare(x1, x2)

fn cmp_p (p1: passenger, p2: passenger):<cloref> Sgn = compare(p1, p2)

macdef map_insert_opt(m, key, itm) =
  $Map.linmap_insert_opt(,(m), ,(key), ,(itm), cmp)

local
  var waiting : map (floor, set(passenger)) with pfw =
    $Map.linmap_make_nil()
  
  var onboard : set(id) with pfo =
    $Set.linset_make_nil()
  

  viewdef waiting = map(floor, set(passenger)) @ waiting
  viewdef onboard = set(passenger) @ onboard

  prval lockw = viewlock_new{waiting}(pfw)
  prval locko = viewlock_new{onboard}(pfo)
in
  val waiting_lock = @{lock= lockw, p= &waiting}
  val onboard_lock = @{lock= locko, p= &onboard}
end

(* ****** ****** *)

implement arrive (p) = let
  val (pf | waiting) = global_get(waiting_lock)
  val floor = get_floor(p)
  val _ = publish_event("service", get_id(p), floor, Some(get_direction(p)))
  val opt = 
    $Map.linmap_search_opt<floor, set(passenger)>(!waiting, floor, cmp)
in
  case+ opt of
    | ~None_vt() => let
      val sing = $Set.linset_make_sing(p)
      val ok = 
        $Map.linmap_insert_opt<floor, set(passenger)>(!waiting, floor, sing, cmp)
     in
      case+ ok of
        | ~None_vt() => () where {
          val _ = global_return(waiting_lock, pf)
        }
        | ~Some_vt(old) => $Set.linset_free(old) where {
          val _ = global_return(waiting_lock, pf)
        }
     end
    | ~Some_vt(ref) => {
      val (minus, setpf | set) = ref
      val _ = $Set.linset_insert<passenger>(!set, p, cmp_p)
      prval () = minus_addback(minus, setpf | !waiting)
      prval () = global_return(waiting_lock, pf)
    }
end

(* ****** ****** *)

implement board(floor, direction) = let
  val (pf | waiting) = global_get(waiting_lock)
  val opt = $Map.linmap_search_opt(!waiting, floor, cmp)
in
  case+ opt of
    | ~None_vt () => list_nil () where {
        prval () = global_return(waiting_lock, pf)
    }
    | ~Some_vt (ref) => let
      val (minus, setpf | p) = ref
      val entering = list_of_list_vt(
        $Set.linset_listize_free<passenger>(!p)
      )
      val () = !p := $Set.linset_make_nil{passenger}()
      fun enter_elevator(p: passenger):<cloref1> Option(request) = let
        val usersdir = get_direction(p)
      in
        if usersdir = direction then let
        val min =
          case+ usersdir of
            | Up () => floor + 1
            | Down() => 1
        val max =
          case+ usersdir of
            | Up () => 10
            | Down() => floor - 1
       val nxt = random_number(min, max)
       val () = set_destination(p, nxt)
       val (boardpf | onboard) = global_get(onboard_lock)
       val _ = $Set.linset_insert(!onboard, p, cmp_p)
       prval () = global_return(onboard_lock, boardpf)
       val () = wait(1)
       val () = publish_event("request", get_id(p), nxt, None)
      in Some(GoToFloor(nxt)) end
      else
        None()
      end
      prval () = minus_addback(minus, setpf | !waiting)
      
      val opt_requests = list_of_list_vt(
        list_map_cloref(entering,
          enter_elevator
        )
      )
      fun collect (
        res: List_vt(request), r: Option(request)
      ): List_vt(request) =
        case+ r of
          | Some(r) => list_vt_cons(r, res)
          | None () => res
      val requests = list_of_list_vt (
        list_fold_left_fun<List_vt(request)>(collect, list_vt_nil, opt_requests)
      )
    in
      list_nil where {
        prval () = global_return(waiting_lock, pf)
      }
    end
end

(* ****** ****** *)

implement leave(floor) = {
  val (pf | onboard) = global_get(onboard_lock)
  val passengers = list_of_list_vt(
    $Set.linset_listize(!onboard)
  )
  val _ = list_foreach_cloref(passengers, lam (p) =<cloref1>
    if get_floor(p) = floor then {
      val (pf | onboard) = global_get(onboard_lock)
      //Remove from elevator
      val _ = $Set.linset_remove<passenger>(!onboard, p, cmp_p)
      //Give them a second to leave.
      val _ = wait(1)
      //Publish the event
      val _ = publish_event("exit", get_id(p), floor, None)
      prval () = global_return(onboard_lock, pf)
    }
  )
  prval () = global_return(onboard_lock, pf)
}

(* ****** ****** *)