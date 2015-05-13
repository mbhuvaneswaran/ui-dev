main.filter('appointmentStatus', ->
  (input, appointmentStatus, location, provider, staff) ->
    appointmentStatus = [appointmentStatus] if not typeIsArray appointmentStatus

    filtered = []
    for entry in input
      hasLocation = (!location? or
      entry.serviceLocationId is location.serviceLocationId)

      hasProvider = ( !(provider? or staff?) or
      provider? and entry.providerId is provider.providerId)

      hasStaff = (!(staff? or provider?) or
      staff? and entry.resourceId is staff.resourceId)

      if entry.appointmentStatus in appointmentStatus and
      hasLocation and ( hasProvider or hasStaff )
        filtered.push entry

    entry = null

    return filtered
)