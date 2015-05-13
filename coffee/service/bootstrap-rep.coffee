main.service 'BootstrapRepository', [
  '$http', 'UrlFor', 'authenticatedUser',
  ($http, UrlFor, authenticatedUser) ->

    auth_user_loaded = false
    authenticatedUser.get().then ->
      auth_user_loaded = true

    defaultUrl = UrlFor.api( 'BootStrap' )

    getDefaultUrl: ->
      defaultUrl

    getBootstrapData: (data) ->
      $http.put(defaultUrl, data)

    ###
    Get data from the aggregate web API and load services with retrieved data.
    Skip services that have been loaded already (based on .hasLoaded or the
    authenticated user state)

    @example
      BootstrapRepository.filteredLoad
        Pref:        Prefs
        Location:    [Locations, query]
        RecentChart: recentCharts

    @param [object] map key-value pairs of UrlFor literal keys and service or
                        [service, query] values
    @return [object] promise
    ###
    filteredLoad: (map) ->
      load_list  = []
      match_list = []
      for resource, v of map
        [service, query] = (if v instanceof Array then v else [v])
        unless service.directLoad? or service.setData?
          throw new Error 'non-standard service requested for: ' + resource

        if service.setData?
          continue if auth_user_loaded
        else
          continue if service.hasLoaded

        load_list.push if query? then {resource, query} else {resource}
        match_list.push service

      if load_list.length
        promise = @getBootstrapData load_list

        promise.success (data) ->
          for service, i in match_list
            if service.setData?
              service.setData data[i].body
            else
              service.directLoad data[i].body

        promise.error (args...) ->
          for service in match_list
            service.directLoadError?()
          console.error 'bootstrap error', args...
  ]