
CalendarSetupCtrl.controller 'CalendarOfficeHoursCtrl', [
  '$scope', '$timeout', 'FeatureToggle', 'Prefs', 'Pros', 'OfficeHrs',
  'Resources',
  ($scope, $timeout, FeatureToggle, Prefs, Pros, OfficeHrs,
  Resources) ->
    $scope.debug = false

    breaks_category_id = 2

    # event unsubscriber
    unsub = Prefs.unsubscriber()

    # unsubscribe from listeners when controller gets pulled
    $scope.$on '$destroy', unsub

    $scope.provider_office_hours = {}
    $scope.staff_office_hours = {}
    $scope.staff_enabled = false

    unsub.add FeatureToggle.if 'load', ->
      $scope.staff_enabled =
        FeatureToggle.enabled[FT_DARK_NON_PROVIDER_CALENDARS]

      unsub.add Prefs.if1 'load', ->
        unsub.add OfficeHrs.if 'load', 'update', (data, status) ->
          unsub.add Pros.if 'load', ->
            $scope.providers = Pros.data
            empty_object $scope.provider_office_hours
            for item in $scope.providers
              $scope.provider_office_hours[item.id] = OfficeHrs.groupByDay(
                  OfficeHrs.findBy('providerId', item.id) or []
              )

          unsub.add Resources.if 'load', 'update', ->
            $scope.staff = Resources.findByResourceType 'staff'
            empty_object $scope.staff_office_hours
            for item in $scope.staff
              $scope.staff_office_hours[item.id] = OfficeHrs.groupByDay(
                  OfficeHrs.findBy('resourceId', item.id) or []
              )

    $scope.getHours = (type, id, dayOfWeek) ->
      if type is 'provider'
        return 'loading' if not $scope.provider_office_hours?
        days = $scope.provider_office_hours[id]
      else if type is 'staff'
        return 'loading' if not $scope.staff_office_hours?
        days = $scope.staff_office_hours[id]
      else
        return null

      return null if not days
      items = days[dayOfWeek]
      return null if not items

      hours_arr = []

      # filter out the officeHours breaks
      items = items.filter (x) ->
        x.saved.officeHrsCategory != breaks_category_id

      items.sort (a, b) ->
        a.saved.startTime > b.saved.startTime

      for item in items
        start = DateConverter::formatTimeOfDayFromMS(item.saved.startTime)
        end = DateConverter::formatTimeOfDayFromMS(item.saved.endTime)
        hours_arr.push "#{start}-#{end}"

      hours_arr.join(', ')
]
