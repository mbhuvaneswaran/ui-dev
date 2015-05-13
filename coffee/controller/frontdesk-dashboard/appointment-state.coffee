# The AppointmentState Controller handles transitioning appointments between
# each state. It's also responsible for handling the patient dropdown
# at this time, however that will likely change as the dropdown gets built

AppointmentStateCtrl = FrontdeskDashboardCtrl.controller 'AppointmentStateCtrl',
[

  '$scope', '$timeout', '$interval', 'Appts', 'AppointmentRepository',
  'LoggerFactory','PatientAlerts', 'PatientBalanceRepository',
  'SynchronizedAppt', 'UrlFor', 'FeatureToggle', 'featureSet', 'InsuranceService', 'PatientService'
  ( $scope, $timeout, $interval, Appts, AppointmentRepository,
  LoggerFactory, PatientAlerts, PatientBalanceRepository,
  SynchronizedAppt, UrlFor, FeatureToggle,featureSet, insuranceService, patientService) ->

    dropdownCloseDelay = 500
    listResetDelay = 400
    retryDelay = 200
    appointmentOpenDelay = 50

    $scope.selectedAppointment = null
    $scope.PatientAlerts = PatientAlerts
    featureSet.load()
    featureHash = {}
    featureSet.load().then( (response) ->
      featureHash = response
      )

    $scope.isDashboardEligibilityEnabled = ()->
       return !!featureHash['dark-feature.dashboard-eligibility']
    data = $scope.data

    $scope.data.loading = false
    logger = LoggerFactory.getLogger(enabled=false, "AppointmentStateCtrl")

    unsubscribe = PatientAlerts.unsubscriber()

    #################################################################
    ## CALENDAR INTEGRATION HOOKS
    #################################################################
    integrationHookUpsertAppt = (appt_data) ->
      logger.trace( 'integrationHookUpserAppt called with', appt_data )
      Appts.upsert( appt_data ) if Appts.data?.length >= 0

    integrationHookCutAppt = (delete_id, occurrenceId) ->
      id = "#{delete_id}-#{occurrenceId}"
      logger.trace( 'integrationHookCutAppt called with', id )
      appt = Appts.get( id )
      Appts.cut( appt ) if appt

    #################################################################
    ## APPOINTMENT DROPDOWN HANDLERS
    #################################################################
    $scope.togglePatientDropdown = (appointment) ->
      # if the appointment status has been updated, and then the UI gets
      # toggled, we'll want to move the appt out of its 'intermediate state'
      # and into its actual state
      if $scope.selectedAppointment != null and
        $scope.selectedAppointment?.intermediateState

          _appt = $scope.selectedAppointment

          $scope.forceClosePatientDropdown()

          $timeout(->
            $scope.intermediateStateToCurrentState(_appt.appointmentId)
            $scope.setAppointmentLists(true)
          , dropdownCloseDelay)

          return

      if appointment and $scope.selectedAppointment is null or
        $scope.selectedAppointment != appointment

          $scope.data.isAppointmentAnimated = true
          $scope.selectedAppointment = appointment
          $scope.patientAlertsLoaded = false
          $scope.data.loadingInsurance = true
          $scope.data.loadingEligibility = true
          $scope.insuranceName = null
          insuranceService.getPatientInsuranceName(appointment.practiceId,appointment.patientSummary.patientId).then (response) ->
            $scope.insuranceData = response.data
            $scope.data.loadingInsurance = false
            if $scope.insuranceData
              $scope.insuranceName = $scope.insuranceData.insuranceName
            else
              $scope.insuranceName = null
          $scope.lastEligibilityData = null
          patientService.getLastEligibilitySummary(appointment.practiceId,appointment.patientSummary.patientId).then (response) ->
            $scope.data.loadingEligibility = false
            $scope.lastEligibilityData = response.data
            $scope.prepareEligibiltyData($scope.lastEligibilityData)

          $timeout(->
            logger.trace( 'Opening Appointment', appointment.appointmentId )
            $scope.data.isAppointmentOpen = true
            if $scope.data.practice.pmenabled
              $scope.getPatientBalance(appointment)

            if appointment.profileData.needsUpdatedClinicalNoteButton or
            appointment.profileData.hasResource
              # bypass the typical process check
              $scope.synchronizedApptLoaded = true
              $scope.synchronizedApptFound = true
            else
              $scope.getSynchronizedAppointment(appointment)

            if data.features.patient_alerts
              $scope.getPatientAlerts(appointment)

          , appointmentOpenDelay)
      else
        $scope.data.isAppointmentOpen = false
        $timeout(->
          $scope.data.isAppointmentAnimated = false
          $scope.selectedAppointment = null

          $scope.synchronizedApptLoaded = false

        , dropdownCloseDelay)

    $scope.forceClosePatientDropdown = (callback) ->
      $scope.data.isAppointmentOpen = false
      $timeout(->
        $scope.selectedAppointment = null
        $scope.patientAlertsLoaded = false

        if callback
          callback()
      , dropdownCloseDelay)

    $scope.createRecurringClinicalNote = ( appointment ) ->
      $scope.recurringAppointmentToInstance( appointment, true, {
        success : (appointment) ->
          $scope.synchronizedApptLoaded = false
          window.location.href = UrlFor.ehrNewNoteLinkUpdated(
            appointment.updateData
          )
        error : ( data ) ->
          alert("An error occurred creating the recurring clinical note link.")
      })


    #################################################################
    ## APPOINTMENT LOADING STATE
    #################################################################
    $scope.setCurrentLoader = (item) ->
      $scope.data.currentLoader = item

    #################################################################
    ## APPOINTMENT STATE HANDLERS and HELPERS
    #################################################################
    $scope.changeAppointmentState = (appointment, state, isIntermediateState) ->
      allowUpdate = true
      $scope.data.loading = true

      if state in $scope.appointmentState.COMPLETED and !appointment.recurring
        allowUpdate = false
        $scope.removeAllAppointmentResources(appointment)

      instanceLoad = $interval(->
        if allowUpdate or appointment.resourceIds.length is 0

          if appointment.intermediateState
            appointment = $scope.intermediateStateToCurrentState(
              appointment.appointmentId
            )

          $scope.updateAppointmentStatus(
            appointment, state, isIntermediateState
          )
          $interval.cancel(instanceLoad)
      , retryDelay)


    $scope.selectAppointmentRoom = (appointment, room) ->
      $scope.allowRoomUpdate = false

      # check for an existing room on the appointment
      for resource, index in $scope.getAppointmentResources(
        appointment.resourceIds)

          if resource.resourceTypeId is ResourceModel.ROOM_RESOURCE
            appointment.resourceIds.splice(index, 1)
            AppointmentRepository.removeAppointmentResource(
              appointment.appointmentId, resource.resourceId)

      $scope.changeAppointmentState(
        appointment, $scope.appointmentStatus.ROOMED, false
      )

      # theres a problem here with recurring appts. We cannot add a resource
      # to a recurring appt, we'll instead have to add a resource to the
      # appt instance. However, that instance hasn't been generated yet, so
      # we'll have to wait until that instance gets created, and add the appt
      # resource to the created instance. Fun, I know.
      # In the case that the appointment instance already exists,
      # we'll have to wait for the update data to come back. Also kind of ugly.
      instanceLoad = $interval(->
        if $scope.allowRoomUpdate
          if appointment.recurring
            for appt, index in $scope.data.appointments
              if appt.createdFromId is appointment.appointmentId
                $scope.createAppointmentResource(
                  $scope.data.appointments[index], room
                )
                break
          else
            for appt, index in $scope.data.appointments
              if appt.appointmentId is appointment.appointmentId
                $scope.createAppointmentResource(appt, room)
                break

          $interval.cancel(instanceLoad)
      , retryDelay)

    $scope.showArrived = (appointment) ->
      $scope.appointmentHasState(appointment.appointmentStatus,
        $scope.appointmentState.SCHEDULED) or
        ( appointment.intermediateState? and
        $scope.appointmentHasState(appointment.appointmentStatus,
          $scope.appointmentStatus.CHECKED_IN) )

    $scope.showReady = (appointment) ->
      $scope.appointmentHasState(appointment.appointmentStatus,
        $scope.appointmentStatus.CHECKED_IN) or
        ( appointment.intermediateState? and
        $scope.appointmentHasState(appointment.appointmentStatus,
          $scope.appointmentState.SCHEDULED) )

    $scope.showRooms = (appointment) ->
      $scope.appointmentHasState(
        appointment.appointmentStatus, $scope.appointmentStatus.READY_TO_BE_SEEN
      )

    $scope.showCheckout = (appointment) ->
      $scope.appointmentHasState(
        appointment.appointmentStatus, $scope.appointmentStatus.ROOMED)

    $scope.showArrivedButton = (appointment) ->
      $scope.appointmentHasState(appointment.appointmentStatus,
        $scope.appointmentState.SCHEDULED) and
        !appointment.intermediateState and $scope.data.loading is false

    $scope.showReadyButton = (appointment) ->
      $scope.showReady(appointment)

    $scope.showScheduleFollowUp = (appointment) ->
      $scope.appointmentHasState(
        appointment.appointmentStatus, $scope.appointmentStatus.CHECKED_OUT
      )

    $scope.showReschedule = (appointment) ->
      $scope.appointmentHasState(
        appointment.appointmentStatus, $scope.appointmentState.CANCELLED
      )

    #################################################################
    ## HTTP DATA CALLS
    #################################################################
    $scope.recurringAppointmentToInstance =
    (appointment, showIntermediate, callbacks) ->
      if appointment.recurring
        appointmentInstance = AppointmentModel::cloneAppointmentInstance(
          appointment, -1
        )
      AppointmentRepository.createAppointment(appointmentInstance)
      .success( (newAppointment) ->
        AppointmentRepository.createAppointmentOccurrenceException(
          appointment.appointmentId, appointment.occurrenceId,
          newAppointment.appointmentId)
        .success( (data) ->
          logger.trace( 'successfully added recurrence exception', data )

          $scope.handleRecurringAppointmentInstancecreation(
            appointment, newAppointment, showIntermediate
            , {
                success: (appt) ->
                  callbacks?.success?( appt )
                error: (data) ->
                  callbacks?.errors?( data )
            })
        )
        .error( (data, status) ->
          console.log "ERROR", status, data
        )
    )
      
    $scope.handleRecurringAppointmentInstancecreation =
    (oldAppointment, appointment, intermediateState, callbacks) ->
        integrationHookUpsertAppt( appointment )

        integrationHookCutAppt( oldAppointment.appointmentId,
            oldAppointment.occurrenceId )

        for entry, index in $scope.data.appointments
          if entry.appointmentId is oldAppointment.appointmentId
            newAppointment = entry
            newIndex = index
            break

        if(intermediateState)
          $scope.data.appointments[index].updateData =
            $scope.prepareRawAppointment(appointment)
          $scope.data.appointments[index].intermediateState = true
          $scope.data.appointments[index].nextState =
            appointment.appointmentStatus
          $scope.data.loading = false

          callbacks?.success?( $scope.data.appointments[index] )
        else
          $scope.forceClosePatientDropdown()

          $timeout(->
              $scope.data.appointments[index] =
                $scope.prepareRawAppointment(appointment)
              $scope.data.appointments[index].createdFromId =
                oldAppointment.appointmentId

              $timeout(->

                callbacks?.success?( $scope.data.appointments[index] )
                $scope.setAppointmentLists(true)
                $scope.allowRoomUpdate = true
                $scope.data.loading = false
              , listResetDelay)
          , dropdownCloseDelay)

    $scope.updateAppointmentStatus =
    (appointment, appointmentStatusId, intermediateState) ->
        AppointmentRepository.updateAppointmentStatus(
          appointment.appointmentId, appointmentStatusId, appointment.occurrenceId)
            .success( (data) ->
              # if this is a recurring appointment, then just want to create
              # a new appointment instance
              if appointment.recurring
                return $scope.handleRecurringAppointmentInstancecreation(
                  appointment, data, intermediateState)

              integrationHookUpsertAppt( data )

              for entry, index in $scope.data.appointments
                if entry.appointmentId is appointment.appointmentId
                  updated = entry
                  updatedIndex = index

              if intermediateState
                $scope.data.appointments[updatedIndex].intermediateState = true
                $scope.data.appointments[updatedIndex].nextState =
                  appointmentStatusId
                $scope.data.appointments[updatedIndex].updateData =
                  $scope.prepareRawAppointment(data)
                $scope.data.loading = false
              else
                $scope.forceClosePatientDropdown(->
                  appointment.isHidden = true
                  $timeout(->
                    $scope.data.loading = false
                    $scope.data.appointments[updatedIndex] =
                      $scope.prepareRawAppointment(data)
                    $scope.setAppointmentLists(true)
                    $scope.allowRoomUpdate = true
                  , 75)
                )
            )
            .error( (data, status) ->
              console.log "ERROR", status, data
            )

    $scope.createAppointmentResource = (appointment, room) ->
      AppointmentRepository.createAppointmentResource(
        appointment.appointmentId, room.resourceId)
        .success( (data) ->
          appointment.resourceIds.push(room.resourceId)

          integrationHookUpsertAppt( appointment )
        )
        .error( (data, status) ->
          console.log "ERROR", status, data
        )

    $scope.removeAllAppointmentResources = (appointment) ->
      for resourceId, index in appointment.resourceIds
        AppointmentRepository.removeAppointmentResource(
          appointment.appointmentId, resourceId)
      appointment.resourceIds = []

    $scope.getPatientBalance = (appointment) ->
      $scope.data.loadingAmounts = true
      $scope.data.balanceAmount = 0
      $scope.data.unappliedAmount = 0
      PatientBalanceRepository.getBalance(appointment.patientSummary.patientId)
      .success( (data) ->
        $scope.data.balanceAmount = data.remainingPatientAmount
        $scope.data.unappliedAmount = data.unappliedPatientAmountToday
        $scope.data.loadingAmounts = false
      )
      .error( (data, status) ->
        console.log "ERROR", status, data
        $scope.data.balanceAmount = 'error retrieving data'
        $scope.data.unappliedAmount = 'error retrieving data'
        $scope.data.loadingAmounts = false
      )

    $scope.getSynchronizedAppointment = (appointment) ->
      logger.trace(" retrieving synchronized appointment ",
        "AppointmentUuid: #{appointment.appointmentUUID}",
        "occurrenceId: #{appointment.occurrenceId}")

      $scope.synchronizedApptLoaded = false
      $scope.synchronizedApptData = null

      appt = new SynchronizedAppt()
      payload = {
        uuid : appointment.appointmentUUID
      }
      if appointment.occurrenceId
        payload.occurrenceId = appointment.occurrenceId
      
      appt.load( payload )

      unsubscribe.add appt.if1 'load', ->
        $scope.synchronizedApptLoaded = true
        $scope.synchronizedApptFound = true
        $scope.synchronizedApptData = appt.data

      unsubscribe.add appt.if1 'load-error', ->
        $scope.synchronizedApptLoaded = true
        $scope.synchronizedApptFound = false
        $scope.synchronizedApptData = null

    $scope.getPatientAlerts = (appointment) ->
      logger.trace( "retrieving patient alerts for appointment " +
        appointment.appointmentId )

      PatientAlerts.clear()
      PatientAlerts.load( appointment.patientSummary.patientId )
      $scope.patientAlertsLoaded = false
      $scope.patient_alert_messages = null

      unsubscribe.add PatientAlerts.if 'load', ->
        if PatientAlerts.data[0]?.data.showInAppointment
          $scope.patient_alert_messages = PatientAlerts.data[0].messageParts()
        $scope.patientAlertsLoaded = true

      unsubscribe.add PatientAlerts.if 'load-error', ->
        $scope.patientAlertsLoaded = true

    $scope.$on '$destroy', unsubscribe

    #################################################################
    ## HELPERS
    #################################################################
    $scope.appointmentHasState = (appointmentStatus, state) ->
      state = [state] if not typeIsArray state
      return appointmentStatus in state if state?
      false

    $scope.getAppointmentResources = (resourceIds) ->
      resources = []

      return resources if not $scope.data.rooms?

      for resource in $scope.data.rooms
        if resource.resourceId in resourceIds
          resources.push resource
      return resources

    $scope.intermediateStateToCurrentState = (appointmentId) ->
      for entry, index in $scope.data.appointments
        if entry.appointmentId is appointmentId and entry.intermediateState
          $scope.data.appointments[index] = entry.updateData
          return $scope.data.appointments[index]

    $scope.isPatientPhotoEnabled = ()->
      return FeatureToggle.enabled[FT_DARK_DASHBOARD_PATIENT_PHOTOS]

    $scope.hasClinicalFeature = ()->
      return featureSet.hasClinicalFeatures()

    $scope.getPatientUrl = (patientId) ->
      if $scope.hasClinicalFeature()
        UrlFor.ehrFacesheet patientId
      else
        UrlFor.ehrDemographics patientId

    #################################################################
    ## EXECUTIONERS
    #################################################################

    if $scope.data.defaultAppointment
      $scope.togglePatientDropdown($scope.data.defaultAppointment)

    $scope.prepareEligibiltyData = (eligibilityData) ->
      $scope.lastChackedDate = null

      if eligibilityData.requestDate != null
        lastEligibilityrequestDate = eligibilityData.requestDate
        dateDiffernce = Math.abs(lastEligibilityrequestDate - new Date().getTime());
        days = dateDiffernce / (1000 * 3600 * 24)                 # no of days
        hrs = (dateDiffernce % 86400000) / 3600000;              # differnce in minute
        mins = ((dateDiffernce % 86400000) % 3600000) / 60000;   # differrence in hour
        if Math.floor(days) == 1
          $scope.lastChackedDate = '1 day ago'

        else if days > 1
         $scope.lastChackedDate = Math.floor(days) + ' days ago'

        else if Math.floor(hrs) == 1
          $scope.lastChackedDate = '1 hour ago'

        else if hrs > 1
         $scope.lastChackedDate = Math.floor(hrs) + ' hours ago'

        else if Math.floor(mins) == 1
          $scope.lastChackedDate = '1 minute ago'

        else if hrs <= 1 && mins > 1
          $scope.lastChackedDate = Math.floor(mins) + ' minutes ago'

        else if mins < 1
          $scope.lastChackedDate = 'Just now'

      # if eligibility status is INELIGIBILE

        $scope.lastDate = null
        lastDateMili = new Date(parseInt(lastEligibilityrequestDate))
        $scope.lastDate = ("0" + (lastDateMili.getMonth() + 1)).slice(-2) + "/" + ("0" + lastDateMili.getDate()).slice(-2) + "/" + lastDateMili.getFullYear()

      #creating eligibilityStatus

      $scope.eligibilityStatus = null
      if eligibilityData.eligibilityStatus == 'ELIGIBLE'
        $scope.eligibilityStatus = 'Verified ' + $scope.lastChackedDate

      else if eligibilityData.eligibilityStatus == 'INELIGIBLE'
        $scope.eligibilityStatus = 'Patient not covered as of ' + $scope.lastDate

      else if eligibilityData.eligibilityStatus == 'UNKNOWN'
        $scope.eligibilityStatus = 'Could not be determined'

      else
        $scope.eligibilityStatus = 'Eligibility check available'

    $scope.data.loadingEligibility = false
    $scope.data.showAdditionalMessage = false

    $scope.runEligibilityCheck = (practiceId, patientId, providerId) ->
      delay = 3500 # as per requirement we need display message on UI after 3.5 secs = 3500 millis
      $timeout (->
        if $scope.data.loadingEligibility
          $scope.data.showAdditionalMessage = true
      ), delay

      $scope.data.loadingEligibility = true
      patientService.performEligibilityCheck(practiceId, patientId, providerId).then (response) ->
        $scope.lastEligibilityData = response.data
        if $scope.lastEligibilityData.eligibilityStatus == null && $scope.lastEligibilityData.realTimeEligibilityChecks
         $scope.runNowEligibilityCheck()
        else
          $scope.prepareEligibiltyData($scope.lastEligibilityData)
        $scope.data.loadingEligibility = false
        $scope.data.showAdditionalMessage = false

    $scope.runNowEligibilityCheck = () ->
      $scope.eligibilityStatus = 'Could not be determined'
      $scope.lastEligibilityData.eligibilityStatus = 'UNKNOWN'
      $scope.lastEligibilityData.realTimeEligibilityChecks = true



]
