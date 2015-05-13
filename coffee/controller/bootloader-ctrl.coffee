BootloaderCtrl = main.controller 'BootloaderCtrl', [
  '$scope', 'Appts', 'ApptReasons', 'BootstrapRepository', 'FeatureToggle',
  'Locations', 'OfficeHrs', 'Prefs', 'Pros', 'Resources', 'practice',
  'privilegeRepository', 'recentCharts', 'userRepository',
  ($scope, Appts, ApptReasons, BootstrapRepository, FeatureToggle,
   Locations, OfficeHrs, Prefs, Pros, Resources, practice,
   privilegeRepository, recentCharts, userRepository) ->

    ########################################################
    ## INITIAL BOOTSTRAP DATA LOAD
    ########################################################
    # Bootstrap
    query = deleted: false

    BootstrapRepository.filteredLoad
      PracticeFeatures: FeatureToggle
      Pref:        Prefs
      Location:    [Locations, query]
      ApptReason:  [ApptReasons, query]
      OfficeHr:    [OfficeHrs, query]
      Pro:         [Pros, query]
      Practice:    [practice, query]
      Resource:    [Resources, query]
      User:        userRepository
      RecentChart: recentCharts
      Privilege:   privilegeRepository
]