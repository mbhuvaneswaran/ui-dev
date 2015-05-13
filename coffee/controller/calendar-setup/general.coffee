CalendarSetupCtrl.controller 'CalendarSetupGeneralCtrl', [
  '$scope', '$timeout', 'Prefs', 'Pref', 'Timezones', 'WebTracking'
  ($scope, $timeout, Prefs, Pref, Timezones, WebTracking) ->
    default_duration = 10
    default_timezone = "America/Los_Angeles"

    wt = WebTracking

    $scope.form = form = {}
    $scope.saving = false

    $scope.tz_name = timezone_name = 'calendar.time_zone'
    $scope.duration_name = duration_name = 'calendar.minute_increment'

    $scope.durationSlots = (n + ' minutes' for n in [5, 10, 15, 20, 30, 60])

    $scope.save = (pref) ->
      $scope.saving = true

      if pref is timezone_name
        data = {
          name: timezone_name,
          value: form.timezone
        }
        wt.track 'calendar-settings.interaction.general-time-zone-changed'
      else if pref is duration_name
        data = {
          name: duration_name,
          value: form.duration.replace " minutes", ''
        }
        wt.track 'calendar-settings.interaction.general-increment-changed'

      pref = new Pref(data)
      pref.save(->
        $timeout(->
          Prefs.load()
          $scope.saving = false
        , 500)
      )

    Prefs.if1 'load', ->
      Timezones.if1 'load', ->

        duration = Prefs.incrementMinute or default_duration
        timezone = Prefs.tz or default_timezone

        $scope.defaults = {
          timezone: timezone,
          duration: duration + ' minutes'
        }

        $scope.timezones = Timezones.data

        # initialize the form values
        form['timezone'] = $scope.defaults.timezone
        form['duration'] = $scope.defaults.duration

]
