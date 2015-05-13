main.filter('dashboardInOffice', ->
  (input, appointmentStatuses) ->

    waiting = []
    arrived = []
    roomed = []
    other = []

    for entry in input
      if entry.appointmentStatus is appointmentStatuses.READY_TO_BE_SEEN
        waiting.push entry
      else if entry.appointmentStatus is appointmentStatuses.CHECKED_IN
        arrived.push entry
      else if entry.appointmentStatus is appointmentStatuses.ROOMED
        roomed.push entry
      else
        other.push entry

    entry = null

    return ( ( waiting.concat(arrived) ).concat(roomed) ).concat(other)
)