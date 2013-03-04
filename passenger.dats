import Global = "contrib/global"

staload Global("global.sats")

staload "simulator.sats"
staload "elevator.sats"
staload "passenger.sats"

(* ****** ****** *)

assume passenger = '{
  id= id,
  dir= direction,
  start= floor,
  destination= floor
}

local 
  var next_id : int with pfid = 1
  
  viewdef next_id = int @ next_id
  
  prval idlock = viewlock_new{next_id}(pfid)
in
  val next_id_lock = @{lock=idlock, p= &next_id}
end

implement make_passenger (start, direction, floor) = let
  val id = new_id()
  val min =
    case+ direction of
      | Up () => floor + 1
      | Down() => 1
  val max =
    case+ direction of
      | Up () => 10
      | Down() => floor - 1
  val dest = $effmask_all(
    random_number(min, max)
  )
in
  '{id= id, dir= direction, start= floor, destination= dest}
end

implement new_id () = new where {
  val (pf | id) = global_get(next_id_lock)
  val new = !id
  val () = !id := !id + 1
  prval () = global_return(next_id_lock, pf)
}

implement get_id(p) = p.id

implement get_floor(p) = p.start

implement get_direction(p) = p.dir

implement get_destination(p) = p.destination

implement compare_passenger_passenger(p1,p2) = compare(p1.id, p2.id)

implement eq_passenger_passenger(p1,p2) = p1.id = p2.id
