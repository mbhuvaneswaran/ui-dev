
animated_scroll = (node, to_x, to_y, time_span=100, $timeout, callback) ->
  # clear previous animations if any
  schedule_property = '__anim_scroll_schedule'
  node[schedule_property] = node[schedule_property] or []
  while node[schedule_property].length
    try
      clearTimeout node[schedule_property].shift()

  return unless to_x? or to_y?

  # start pos
  left = node.scrollLeft
  top  = node.scrollTop

  # animate
  if to_x?
    x_distance     = to_x - left
    x_top_velocity = x_distance / time_span * 4
    x_acceleration = x_top_velocity / time_span
    x_velocity     = 0
  if to_y?
    y_distance     = to_y - top
    y_top_velocity = y_distance / time_span * 4
    y_acceleration = y_top_velocity / time_span
    y_velocity     = 0

  for i in [0 .. time_span] by 1
    if to_x?
      if i < time_span / 2
        x_velocity += x_acceleration
      else
        x_velocity -= x_acceleration
      left += x_velocity
    if to_y?
      if i < time_span / 2
        y_velocity += y_acceleration
      else
        y_velocity -= y_acceleration
      top  += y_velocity

    if i % 5 is 0 or i is time_span
      do (left, top, i) ->
        node[schedule_property].push setTimeout ->
          node.scrollLeft = Math.round left if to_x?
          node.scrollTop = Math.round top if to_y?
        , i

  $timeout(callback, time_span + 5) if callback
