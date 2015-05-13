
DashboardCacheCtrl = FrontdeskDashboardCtrl.controller 'DashboardCacheCtrl', [
  '$scope', '$cookieStore', '$routeParams', '$interval', 'BootstrapRepository',
  'LoggerFactory', 'Prefs', 'Pref', 'timez', '$q',
  'userRepository', 'userAttributeRepository', 'practiceAttributeRepository',
  'practiceFeaturesRepository', 'practice',
  'privilegeRepository', 'recentCharts', 'authenticatedUser', 'Modal',
  'WebTracking', '$location', 'FeatureToggle'
  ( $scope, $cookieStore, $routeParams, $interval, BootstrapRepository,
    LoggerFactory, Prefs, Pref, timez, $q,
    userRepository, userAttributeRepository, practiceAttributeRepository,
    practiceFeaturesRepository, practiceRepository,
    privilegeRepository, recentChartRepository, authenticatedUser, Modal,
    WebTracking, $location, FeatureToggle
  )->

    retryDelay = 50
    reloadCheckInterval = 1000
    loadCheck = null # pointer to the main loop

    data = $scope.data

    # time in seconds
    cacheExpireTime = 60
    lastLoaded = null
    haveSyncedOnce = false
    $scope.loading = true
    $scope.autoload = true unless $scope.autoload?
    $scope.loadState = {error: false}
    $scope.datePickerActive = false;

    logger = LoggerFactory.getLogger(enabled=false, "DashboardCacheCtrl")

    dateSimulator = new DateSimulator($routeParams)

    $scope.Modal = Modal

    keys = $scope.cookie_keys

    #################################################################
    ## DATE CHANGE
    #################################################################
    $scope.$watch('time.string_date', ->
      if $scope.time?.string_date
        $scope.data.string_date = $scope.time.string_date
    )

    $scope.$on('$routeUpdate', ->
      $scope.updateDay( $routeParams ) unless $routeParams.date
    )

    $scope.nextDay = ->
      rp = { date : $scope.time.now.add(1, 'day').format('YYYY-MM-DD') }
      logger.trace('nextDay Obj', rp.date)
      
      $scope.updateDay( rp )
      
    $scope.previousDay = ->
      rp = { date : $scope.time.now.add(-1, 'day').format('YYYY-MM-DD') }
      logger.trace('prevDay Obj', rp.date)
      
      $scope.updateDay( rp )

    $scope.onDateChange = ->
      $scope.datePickerActive = false;
      elem = document.querySelector "#dateOfAppointments"      
      dateString = moment(elem.value).format('YYYY-MM-DD')
      rp = { date : dateString }
      logger.trace('dateChange Obj', rp.date)
      
      $scope.updateDay( rp )

    $scope.onBlurHandler = ->
      $scope.datePickerActive = false;

    $scope.showCalendar = ->
      $scope.datePickerActive = true;
      angular.element(document.querySelector("#dateOfAppointments"))[0].datePicker.show()

    $scope.updateDay = ( simulatedParams ) ->
      dateSimulator = new DateSimulator( simulatedParams )
      $scope.forceReload()
      $scope.data.preDataLoad = true
      $location.search('date', simulatedParams.date)

    $scope.hasClinicalFeature = ()->
      return FeatureToggle.enabled[FT_CLINICAL_FEATURE]

    #################################################################
    ## CACHE
    #################################################################
    $scope.performCacheSync = ->
      safeLoad = $interval(->
        if $scope.cache.serviceLocations? and
          $scope.cache.appointmentReasons? and
          $scope.cache.providers? and
          $scope.cache.resources? and
          $scope.cache.appointments? and
          $scope.cache.practice?

            $scope.data.serviceLocations = $scope.cache.serviceLocations
            $scope.data.appointmentReasons = $scope.cache.appointmentReasons
            $scope.data.providers = $scope.cache.providers
            $scope.data.rooms = $scope.cache.rooms
            $scope.data.practice = $scope.cache.practice
            $scope.data.staff = $scope.cache.staff
            $scope.data.resources = $scope.cache.resources

            $scope.resetLoadedData()

            $scope.data.appointments = []
            for entry in $scope.cache.appointments
              entry = $scope.prepareRawAppointment(entry, Prefs)

              if entry and
                $scope.time.now.date() is entry.profileData.startTime.date()
                  $scope.data.appointments.push entry

            showable = getShowableProvidersAndLocations(
              $scope.data.appointments,
              $scope.data.providers,
              $scope.data.staff,
              $scope.data.serviceLocations
            )

            data.showableProviders = showable.providers
            data.showableLocations = showable.locations
            data.showable = showable

            if not $scope.data.currentLocation?
              if $scope.data.showableLocations?.length > 0
                $scope.data.currentLocation = $scope.data.showableLocations[0]

            $scope.setAppointmentLists()
            $scope.setDefaultAppointmentAndView()

            $scope.resetCache()
            $scope.data.preDataLoad = false

            $interval.cancel(safeLoad)
      , retryDelay)

    $scope.resetLoadedData = ->
      data.cached_providers = {}
      data.cached_resources = {}
      data.cached_appointment_resources = {}
      data.currentStaff = null if data.currentStaff
      data.currentProvider = null if data.currentProvider
      data.currentLocation = null if data.currentLocation

    $scope.loadCache = ->
      if dateSimulator?.hasSimulatedDate()
        logger.log "using simulated time"
        time = moment( dateSimulator.getSimulatedDate() )
      else
        time = moment()

      start = moment(time).startOf('day').subtract(1, 'day')
      end = moment(time).startOf('day').add(2, 'day')

      response = BootstrapRepository.getBootstrapData([
          {
            "resource": "Pref"
          },
          {
            "resource": "Location"
          },
          {
            "resource": "ApptReason"
          },
          {
            "resource": "Resource"
          },
          {
            "resource": "Pro",
            "query": {
              "deleted": false
            }
          },
          {
            "resource": "Practice"
            "query": {
              "deleted": false
            }
          }
          {
            "resource": "Appt"
            "query": {
              "minDate": start.valueOf().toString()
              "maxDate": end.valueOf().toString()
              "deleted": false
              "maxDaysPerPage":3
            }
          },
          {
            "resource": "User"
          },
          {
            "resource": "RecentChart"
          },
          {
            "resource": "Privilege"
          },
          {
            "resource": "PracticeFeatures"
          }
        ])

      response.success( (data) ->
        logger.trace("received successful bootstrap response")

        prefs = data[0].body
        locations = data[1].body
        apptReasons = data[2].body
        resources = data[3].body
        pros = data[4].body
        practice = data[5].body
        practiceRepository.setData(practice)
        appts = data[6].body.results
        userRepository.setData(data[7].body)
        recentChartRepository.setData(data[8].body)
        privilegeRepository.setData(data[9].body)

        FeatureToggle.directLoad( data[10].body )
        $scope.data.FeatureToggle = FeatureToggle

        $scope.cache.serviceLocations = locations
        $scope.cache.appointmentReasons = apptReasons
        $scope.cache.providers = pros
        $scope.cache.practice = practice

        $scope.loadFeatures()


        Prefs.data = []
        for item in prefs
          Prefs.data.push new Pref(item)
        Prefs.loadSpecialValues()
        $scope.data.prefs = Prefs

        $scope.getTimeConstraints(dateSimulator, Prefs)

        $scope.cache.appointments = []
        for entry in appts
          startTime = timez(entry.startTime)

          if startTime.date() == $scope.time.now.date() and
          entry.patientSummary != null

            if entry.providerId? or
            FeatureToggle.enabled[FT_DARK_NON_PROVIDER_CALENDARS]
              $scope.cache.appointments.push entry

        $scope.cache.resources = []
        $scope.cache.rooms = []
        $scope.cache.staff = []
        for resource in resources
          $scope.cache.resources.push resource
          
          if resource.deleted is false
            if resource.resourceTypeId is ResourceModel.ROOM_RESOURCE
                $scope.cache.rooms.push resource

            if FeatureToggle.enabled[FT_DARK_NON_PROVIDER_CALENDARS]
              if resource.resourceTypeId is ResourceModel.STAFF_RESOURCE
                  $scope.cache.staff.push resource

        return
      )

      response.error( (data) ->
        $scope.loadState.error = true
      )

    $scope.hasCache = ->
      Object.keys($scope.cache).length > 0 ? true : false

    $scope.forceReload = ->
      $scope.data.isAppointmentOpen = false
      $scope.data.isAppointmentAnimated = false
      lastLoaded = null

      $interval.cancel( loadCheck )
      $scope.reloadCheck()

    $scope.reloadCheck = ->
      if !lastLoaded && $scope.autoload
        $scope.loadCache()
        $scope.performCacheSync()
        lastLoaded = new Date()

      loadCheck = safeLoad = $interval(->
        needsReload = (lastLoaded) ->
          return true if not lastLoaded

          now = new Date()
          val = parseInt( ( now.getTime() - lastLoaded.getTime() ) / 1000)
          return val > cacheExpireTime ? true : false

        if needsReload(lastLoaded)
          lastLoaded = new Date()
          $scope.loadCache()

        if $scope.hasCache() and !$scope.data.isAppointmentOpen and
          !$scope.data.isAppointmentAnimated
            $scope.performCacheSync()

        $scope.$on '$destroy', ->
          $interval.cancel( safeLoad )

      , reloadCheckInterval)

    $scope.data.preDataLoad = true
    $scope.reloadCheck()

    $scope.closeModal = ->
      $scope.Modal.close()
    $scope.openModal = ->
      $scope.Modal.open('notesTour')

    $q.all( {
        practice: practiceAttributeRepository.get(),
        user: authenticatedUser.get()
    } )
      .then((promises)->

        $scope.clinicalNotePriv =
          authenticatedUser.hasPrivilegeAccess(AUTH__NOTES, AUTH__WRITE)
        $scope.patientApptsPriv =
          authenticatedUser.hasPrivilegeAccess(AUTH__PATIENT_APPTS, AUTH__WRITE)

        $scope.notesTourEnabled = authenticatedUser.isNotesTourEnabled()

        if ($scope.notesTourEnabled and
            authenticatedUser.getNotesTourStatus() == 0 and
            $cookieStore.get("notesTourSeen") != "true") or
            window.location.hash.indexOf('?notes_tour') > 0
          $scope.showNotesTour = true
          $scope.autoStartNotesTour = true
          $scope.openModal()
          $cookieStore.put("notesTourSeen", "true")

        if $scope.notesTourEnabled
          $scope.showNotesTour = $scope.autoStartNotesTour or
            authenticatedUser.getNotesTourStatus() != 2
          $scope.showErxCard = authenticatedUser.canEnrollErx() &&
            !$scope.showNotesTour
          $scope.showPatientUploadCard = !promises.practice.over100Patients &&
            !$scope.showErxCard &&
            !$scope.showNotesTour

      )

    ##
    # Security
    ##
    #authenticatedUser.get().then ->



    #################################################################
    ## HELPERS
    #################################################################
    getShowableProvidersAndLocations = (appointments, providers, staff,
        locations) ->
        providerIds = []
        providerTaken = {}

        staffIds = []
        staffTaken = {}

        locationIds = []
        locationTaken = {}

        default_provider = $cookieStore.get( keys.provider )
        default_loc = $cookieStore.get( keys.location )
        default_staff = $cookieStore.get( keys.staff )

        for entry in appointments
          providerKey = entry.providerId
          locationKey = entry.serviceLocationId
          resourceKey = entry.resourceId

          if not (providerKey of providerTaken) and providerKey?
            providerIds.push providerKey
            providerTaken[providerKey] = true

          if not (locationKey of locationTaken)
            locationIds.push locationKey
            locationTaken[locationKey] = true

          if not (resourceKey of staffTaken) and resourceKey?
            staffIds.push resourceKey
            staffTaken[resourceKey] = true

        showableProviders = []
        for provider in providers
          if provider.providerId in providerIds
            if default_provider and provider.providerId == default_provider
              $scope.changeProvider( provider )

            showableProviders.push provider

        showableStaff = []
        for emp in staff
          if emp.resourceId in staffIds
            if default_staff and emp.resourceId == default_staff
              $scope.changeStaff( emp )
            showableStaff.push emp

        showableLocations = []
        for location in locations
          if location.serviceLocationId in locationIds
            if default_loc and location.serviceLocationId == default_loc
              $scope.changeLocation( location )

            showableLocations.push location

        {
          providers : showableProviders
          staff : showableStaff
          locations : showableLocations
        }

    $scope.loadFeatures = () ->
      $scope.data.features = features = {}

      features['patient_alerts'] =
        FeatureToggle.enabled[FT_DARK_PATIENT_ALERTS]

      features['non_provider_calendars'] =
        FeatureToggle.enabled[FT_DARK_NON_PROVIDER_CALENDARS]

    $scope.setDefaultAppointmentAndView = () ->
      appt_state = $scope.appointmentState
      default_view = $cookieStore.get( keys.view )

      if $scope.data.defaultAppointmentId
        for appointment in $scope.data.appointments
          appt_status = appointment.appointmentStatus

          if appointment.appointmentId is $scope.data.defaultAppointmentId
            $scope.data.defaultAppointment = appointment

            if appt_status in appt_state.IN_OFFICE
              $scope.changeView('inOffice')
            else if appt_status in appt_state.COMPLETED
              $scope.changeView('finished')
            else if appt_status in appt_state.SCHEDULED
              $scope.changeView('upcoming')
      else if default_view
        $scope.changeView( default_view )
]
