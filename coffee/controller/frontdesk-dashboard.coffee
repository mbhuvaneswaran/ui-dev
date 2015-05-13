# The Frontdesk controller handles common functionality between
# the dashboard components

FrontdeskDashboardCtrl = main.controller 'FrontdeskDashboardCtrl', [
  '$cookieStore', '$filter', '$interval', '$routeParams', '$scope', '$timeout',
  'AppointmentReasonRepository', 'AppointmentRepository', 'LoggerFactory',
  'ProviderRepository', 'ResourceRepository', 'ServiceLocationRepository',
  'UrlFor', 'timez'
  ($cookieStore, $filter, $interval, $routeParams, $scope, $timeout,
   AppointmentReasonRepository, AppointmentRepository, LoggerFactory,
   ProviderRepository, ResourceRepository, ServiceLocationRepository,
   UrlFor, timez) ->

    $scope.urlFor = UrlFor

    $scope.data = data = {}
    data.cached_providers = {}
    data.cached_resources = {}
    data.cached_appointment_reasons = {}

    $scope.cache = {}
    $scope.time = {}
    $scope.cookie_keys = keys = {
      provider : 'dashboard-selected-provider'
      staff : 'dashboard-selected-staff'
      location : 'dashboard-selected-location'
      view : 'dashboard-selected-view'
    }

    $scope.showProfileDebugPanel = false

    $scope.data.isAppointmentOpen = false

    $scope.data.defaultAppointmentId = parseInt($routeParams.appointmentId)
    $scope.data.defaultAppointment = null

    $scope.currentView = 'upcoming'

    dateSimulator = new DateSimulator($routeParams)

    $scope.gender = Gender

    logger = LoggerFactory.getLogger(enabled=false, "FrontdeskDashboardCtrl")

    blinkDelay = 3000

    $scope.bucket = bucket = {
      SCHEDULED : 0,
      IN_OFFICE : 1,
      FINISHED : 2
    }

    #################################################################
    ## CACHE MODIFIY
    #################################################################
    $scope.resetCache = ->
      $scope.cache = {}

    #################################################################
    ## VIEW CHANGERS
    #################################################################
    $scope.changeView = (view) ->
      $scope.currentView = view
      $cookieStore.put( keys.view, view )

    $scope.changeLocation = (location) ->
      $scope.data.currentLocation = location
      $scope.setAppointmentLists()

      if location
        $cookieStore.put( keys.location, location.serviceLocationId )
      else
        $cookieStore.remove( keys.location )

    $scope.changeProvider = (provider) ->
      data.currentProvider = provider

      if provider
        $cookieStore.put( keys.provider, provider.providerId )
        $scope.changeStaff( null )
      else
        $cookieStore.remove( keys.provider )

      $scope.setAppointmentLists()

    $scope.changeStaff = (staff) ->
      data.currentStaff = staff
      
      if staff
        $cookieStore.put( keys.staff, staff.resourceId)
        $scope.changeProvider(null)
      else
        $cookieStore.remove( keys.staff )
      
      $scope.setAppointmentLists()

    $scope.setBucketBlink = (bucketToBlink) ->
      if bucketToBlink is bucket.SCHEDULED
        $scope.bucketScheduledBlink = true
      if bucketToBlink is bucket.IN_OFFICE
        $scope.bucketInOfficeBlink = true
      if bucketToBlink is bucket.FINISHED
        $scope.bucketFinishedBlink = true

      $timeout(->
        $scope.bucketScheduledBlink =
        $scope.bucketInOfficeBlink =
        $scope.bucketFinishedBlink = undefined
      , blinkDelay)

    #################################################################
    ## HELPERS
    #################################################################
    $scope.getCachedProvider = (providerId) ->
      return null unless providerId

      if is_object_empty( data.cached_providers )
        data.cached_providers = {} unless data.cached_providers
        for provider in $scope.data.providers
          data.cached_providers[provider.providerId] = provider

      data.cached_providers[providerId]

    $scope.getCachedResource = (resourceId) ->
      return null unless resourceId

      if is_object_empty( data.cached_resources )
        data.cached_resources = {} unless data.cached_resources
        for resource in $scope.data.resources
          data.cached_resources[resource.resourceId] = resource
      
      data.cached_resources[resourceId]

    $scope.getCachedAppointmentReason = (appointmentReasonId) ->
      return null unless appointmentReasonId

      if is_object_empty( data.cached_appointment_reasons )
        for reason in $scope.data.appointmentReasons
          data.cached_appointment_reasons[reason.appointmentReasonId] = reason

      data.cached_appointment_reasons[appointmentReasonId]

    # given a single appointment from the service, prepares it for the UI
    $scope.prepareRawAppointment = (appointment, Prefs) ->
      Prefs = $scope.data.prefs unless Prefs

      appointment.provider = $scope.getCachedProvider(appointment.providerId)
      appointment.resource = $scope.getCachedResource(appointment.resourceId)
      return unless appointment.provider || appointment.resource

      if !appointment.provider? and appointment.resource? and
      appointment.resource.resourceTypeId != ResourceModel.STAFF_RESOURCE
        return

      appointment.appointmentReason =
        $scope.getCachedAppointmentReason(appointment.appointmentReasonId)

      # reference flag, for finding the right appt to add resources to
      appointment.createdFromId = null

      start_time = timez(appointment.startTime).tz(Prefs.tz)

      currTime = $scope.time.now.valueOf()
      apptTime = start_time.valueOf()
      needsExtraGrade = false

      timeParts = DateConverter::getTimeDifferenceParts(apptTime - currTime)

      if timeParts.hours is 0 and timeParts.minutes <= 30
        needsExtraGrade = true

      time_f = 'h:mma'

      display_id = appointment.appointmentId
      display_id += '-' + appointment.occurrenceId if appointment.occurrenceId

      appointment.profileData = {
        startTimeShort: timez(start_time).format(time_f),
        needsExtraGrade : needsExtraGrade
        needsUpdatedClinicalNoteButton : appointment.createdDate > 1410739200000
        startTime: timez(start_time),
        endTime : timez(appointment.endTime).tz(Prefs.tz)
        updatedAt : timez(appointment.updatedAt).tz(Prefs.tz)
        displayId : display_id
        hasResource : !appointment.providerId? && appointment.resourceId?
      }

      patient = appointment.patientSummary

      patient.displayPhone = Format::SimplePhoneFormat(
        $scope.getDisplayPhone( patient )
      )

      patient.displayEmail = $scope.getDisplayEmail( patient )

      patient.yearsOfAge = DateConverter::getYearsOfAge(
        new Date(patient.dateOfBirth)
      )

      return appointment

    $scope.getDisplayPhone = (patient) ->
      mapping = {
        'MOBILE': 'mobilePhone'
        'HOME': 'homePhone'
        'WORK': 'workPhone'
        'OTHER': 'otherPhone'
      }

      if patient.preferredPhoneType and
        ( phone = patient[mapping[ patient.preferredPhoneType ]] )
          return phone

      patient.mobilePhone or
      patient.homePhone or
      patient.workPhone or
      patient.otherPhone

    $scope.getDisplayEmail = (patient) ->
      mapping = {
        'PERSONAL': 'personalEmail'
        'WORK': 'workEmail'
        'OTHER': 'otherEmail'
      }

      if patient.preferredEmailType and
        ( email = patient[ mapping[ patient.preferredEmailType ] ] )
          return email

      patient.email or
      patient.workEmail or
      patient.otherEmail

    $scope.formattedAppointmentTime = (appointmentStartTime, currentTime) ->
      distance = Math.abs(appointmentStartTime - currentTime)
      DateConverter::getShortTimeDifference(distance)

    $scope.appointmentRelativeTime = (appointmentStartTime, currentTime) ->
      appointmentStartTime - currentTime

    $scope.setAppointmentLists = (showBucketBlink) ->
      currScheduledLength = $scope.data.scheduledAppointments?.length
      currInOfficeLength = $scope.data.inOfficeAppointments?.length
      currFinishedLength = $scope.data.finishedAppointments?.length

      $scope.data.scheduledAppointments = $filter('appointmentStatus')(
        $scope.data.appointments, $scope.appointmentState.SCHEDULED,
        $scope.data.currentLocation, $scope.data.currentProvider,
        $scope.data.currentStaff)

      $scope.data.inOfficeAppointments = $filter('dashboardInOffice')(
        $filter('orderBy')(
          $filter('appointmentStatus')(
            $scope.data.appointments, $scope.appointmentState.IN_OFFICE,
            $scope.data.currentLocation, $scope.data.currentProvider,
            $scope.data.currentStaff
          ), 'startTime'
        ), $scope.appointmentStatus)

      $scope.data.finishedAppointments = $filter('appointmentStatus')(
        $scope.data.appointments, $scope.appointmentState.COMPLETED,
        $scope.data.currentLocation, $scope.data.currentProvider,
        $scope.data.currentStaff)

      if showBucketBlink
        if currScheduledLength? and
        $scope.data.scheduledAppointments.length > currScheduledLength
          $scope.setBucketBlink( bucket.SCHEDULED )

        if currInOfficeLength? and
          $scope.data.inOfficeAppointments.length > currInOfficeLength
            $scope.setBucketBlink( bucket.IN_OFFICE )

        if currFinishedLength? and
        $scope.data.finishedAppointments.length > currFinishedLength
          $scope.setBucketBlink( bucket.FINISHED )


    $scope.getTimeConstraints = (dateSimulator, Prefs) ->
      time = {}
      maxDays = 2
      hoursOfDay = 24

      if dateSimulator?.hasSimulatedDate()
        logger.log "using simulated time"
        time.now = timez( dateSimulator.getSimulatedDate() )
        time.isToday = timez().date() == time.now.date()
      else
        time.isToday = true
        time.now = timez()

      time.string_date = time.now.format("ddd, MMM DD, YYYY")

      time.minTime = timez(time.now).startOf('day')
      time.maxTime = timez(time.now).startOf('day').add('days', maxDays)

      logger.log 'current time', time.now
      logger.log "start time", time.minTime.valueOf()
      logger.log "end time", time.maxTime.valueOf()

      $scope.time = time


    #################################################################
    ## EXECUTIONERS
    #################################################################
    appointmentStatus = {
      UNKNOWN : 0
      SCHEDULED : 1
      REMINDER_SENT : 2
      CONFIRMED : 3
      CHECKED_IN : 4
      ROOMED : 5
      CHECKED_OUT : 6
      NEEDS_RESCHEDULE : 7
      READY_TO_BE_SEEN : 8
      NO_SHOW : 9
      CANCELLED : 10
      RESCHEDULED : 11
    }

    $scope.appointmentStatus = appointmentStatus

    $scope.appointmentState = {
      IN_OFFICE: [
        appointmentStatus.READY_TO_BE_SEEN,
        appointmentStatus.CHECKED_IN,
        appointmentStatus.ROOMED
      ],

      SCHEDULED: [
        appointmentStatus.SCHEDULED,
        appointmentStatus.CONFIRMED,
        appointmentStatus.REMINDER_SENT
      ],

      CANCELLED : [
        appointmentStatus.CANCELLED,
        appointmentStatus.NO_SHOW
      ],

      COMPLETED: [
        appointmentStatus.CHECKED_OUT,
        appointmentStatus.CANCELLED,
        appointmentStatus.NO_SHOW,
        appointmentStatus.RESCHEDULED
      ]
    }
]
