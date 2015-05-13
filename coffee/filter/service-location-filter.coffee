main.filter('serviceLocationFilter', ->
  (input, serviceLocation) ->
    
    list = []
    for entry in input
      if entry.serviceLocationId is serviceLocation.serviceLocationId
        list.push entry

    entry = null

    list
)