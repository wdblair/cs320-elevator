staload "passenger.sats"

(* ****** ****** *)

%{
static int new_id;

ats_int_type 
new_id() {
  return new_id++;
}




%}
