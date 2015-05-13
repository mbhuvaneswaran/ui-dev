main.filter('providerLoadFilter', ->
  (input, provider, serviceLocation) ->
    
    list = []
    for entry in input
      if entry.providerId is provider.providerId
        if serviceLocation?
          if serviceLocation.serviceLocationId is entry.serviceLocationId
            list.push entry
        else
          list.push entry

    entry = null

    list
)