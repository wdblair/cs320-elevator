import Global = "contrib/global"

staload Global("global.sats")

staload "simulator.sats"
staload "elevator.sats"
staload "passenger.sats"

staload Map = "libats/SATS/linmap_skiplist.sats"
staload _ = "libats/DATS/linmap_skiplist.dats"
stadef map = $Map.map

staload Set = "libats/SATS/linset_avltree.sats"
staload _ = "libats/DATS/linset_avltree.dats"
stadef set = $Set.set

(* ****** ****** *)

//internal state for the elevator

implement $Map.compare_key_key<int>(k1,k2,cmp) = 
  if k1 < k2 then ~1 else if k1 > k2 then 1 else 0
  
fn cmp (x1: int, x2: int):<cloref> Sgn = compare(x1,x2)


macdef map_insert_opt(m, key, itm) = 
  $Map.linmap_insert_opt(,(m), ,(key), ,(itm), cmp)

local
  var waiting : map (floor, set(passenger)) with pfw =
    $Map.linmap_make_nil()
  
  var onboard : set(passenger) with pfo =
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

