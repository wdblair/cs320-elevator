staload "elevator.sats"

assume nothing = '{
  control= none,
  schedule= indeterminate,
  floor= suspicious
}

assume state = '{
  control= control_state,
  schedule= schedule,
  direction= direction,
  floor= floor
}

implement make_state(c, s, d, f) = '{
  control= c, schedule= s, direction= d, floor= f
}

implement get_control_state(s) = s.control

implement get_schedule(s) = s.schedule

implement state_direction(s) = s.direction

implement get_floor(s) = s.floor
