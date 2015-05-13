
CalendarCtrl.controller 'FilterCtrl', [
  '$scope', 'Pros', 'Resources', 'WebTracking'
  ($scope, Pros, Resources, WebTracking) ->

    $scope.FT_DARK_NON_PROVIDER_CALENDARS = FT_DARK_NON_PROVIDER_CALENDARS

    $scope.checkAll = ->
      full_list = Pros.withResources()

      has_invisible = false

      for provider in full_list
        unless provider.visible or provider.data.resourceTypeId is 1 # excl room
          has_invisible = true
          break

      for provider in full_list
        if provider.data.resourceTypeId isnt 1 # excl room
          provider.visible = has_invisible

          if provider.data.providerId
            pro_changed = true
          else
            rsc_changed = true

      if pro_changed
        Pros.emit 'update'
      if rsc_changed
        Resources.emit 'update'

    $scope.trackProviderSelectedUpdate = ->
      WebTracking.track 'calendar.interaction.week-provider-changed'
]
