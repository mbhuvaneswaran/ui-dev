
CalendarCtrl = main.controller 'CalendarCtrl', [
  '$scope', '$timeout', 'Appts', 'ApptReasons', 'BootstrapRepository',
  'DailyApptCounts', 'FeatureToggle', 'HolidayInstancesChild', 'Locations',
  'Modal', 'OfficeHrs', 'Prefs', 'Pros', 'Resources', 'TimeOffs', 'View',
  'authenticatedUser', 'practice', 'privilegeRepository', 'recentCharts',
  'userRepository',
  ($scope, $timeout, Appts, ApptReasons, BootstrapRepository,
   DailyApptCounts, FeatureToggle, HolidayInstancesChild, Locations,
   Modal, OfficeHrs, Prefs, Pros, Resources, TimeOffs, View,
   authenticatedUser, practice, privilegeRepository, recentCharts,
   userRepository) ->

    # Bootstrap
    query = deleted: false
    BootstrapRepository.filteredLoad
      PracticeFeatures: FeatureToggle
      Pref:             Prefs
      Location:         [Locations, query]
      ApptReason:       [ApptReasons]
      OfficeHr:         [OfficeHrs, query]
      Pro:              [Pros, query]
      Practice:         [practice, query]
      Resource:         [Resources, query]
      User:             userRepository
      RecentChart:      recentCharts
      Privilege:        privilegeRepository

    # Services that should be available on scope for Angular expressions
    # (i.e. in the markup under this controller)
    $scope.ApptReasons = ApptReasons
    $scope.Locations   = Locations
    $scope.Modal       = Modal
    $scope.Pros        = Pros
    $scope.Resources   = Resources
    $scope.View        = View

    $scope.enabledFeature = FeatureToggle.enabled

    # broadcast message on appt-rendering related data change
    appt_cb = (args...) ->
      $scope.$broadcast 'calendar:appt', args...
    for service in [ApptReasons, Appts, DailyApptCounts, HolidayInstancesChild,
                    Locations, OfficeHrs, Pros, Resources, TimeOffs, View]
      service.on 'load', 'update', appt_cb

    # boot-up event subscriptions
    authenticatedUser.get().then ->
      $scope.showSettings =
        authenticatedUser.hasPrivilegeAccess(AUTH__CALENDAR_SETUP, AUTH__WRITE)

      Pros.if1Sync 'load', ->
        View.updateFromUrl()

        View.if1Sync 'core-update', -> # mark as ready when range is defined
          $scope.calendarReady = true
          appt_cb()
]
