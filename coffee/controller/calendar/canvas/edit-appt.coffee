CalendarCanvasCtrl.controller 'EditAppt', [
  '$scope', '$timeout', 'Appts', 'ApptConflict', 'ApptStatus', 'Locations',
  'LoggerFactory', 'Modal', 'Prefs', 'Pros', 'RecurrenceException', 'View',
  'PatientCreateModalService', 'UrlFor', 'WebTracking', 'authenticatedUser',
  'timez','featureSet', 'PatientBalanceRepository',
  ($scope, $timeout, Appts, ApptConflict, ApptStatus, Locations,
   LoggerFactory, Modal, Prefs, Pros, RecurrenceException, View,
   PatientCreateModalService, UrlFor, WebTracking, authenticatedUser,
   timez,featureSet, PatientBalanceRepository) ->

    ##
    # Security
    ##
    authenticatedUser.get().then ->
      $scope.patientApptsPriv =
        authenticatedUser.hasPrivilegeAccess(AUTH__PATIENT_APPTS, AUTH__WRITE)
      $scope.patientDemoPriv =
        authenticatedUser.hasPrivilegeAccess(AUTH__PATIENT_DEMO, AUTH__WRITE)

    record = null

    $scope.resultMax = 12

    $scope.form = form = {}

    $scope.time_f = time_f = 'h:mma'
    $scope.date_f = date_f = 'MM/DD/YYYY'

    max_conflicts = 5
    $scope.conflicts = []

    appt_conflicts = new ApptConflict

    $scope.ApptStatus = ApptStatus
    $scope.ApptConflict = appt_conflicts

    $scope.features = {}
    featureSet.load()
      .then (features) ->
        $scope.features = features
    $scope.UrlFor = UrlFor

    logger = LoggerFactory.getLogger(enabled = false, "EditAppt Controller")

    preload_range = View.range.preload

    unsub = Prefs.unsubscriber()

    # unsubscribe from listeners when controller gets pulled
    $scope.$on '$destroy', ->
      unsub()

    $scope.selectProOrRsc = (selected) ->
      if data = record.data
        xid = Pros.parseXid String $scope.selectedProOrRsc = selected
        data.providerId = xid.providerId
        data.resourceId = xid.resourceId

    $scope.setDayOfWeek = ( record, daysEnum ) ->
      $scope.setLimitView()
      # Sun would be 0, and converted to -1.. Since it's represented
      # last in the UI, we mod this to 6
      d_o_w = ( record.startTime().format('d') - 1 ) %% 7
      record.setRecurrenceDay( d_o_w, true, true)
      daysEnum[ d_o_w ] = record.getRecurrenceDaysEnum()[ d_o_w ]
      $scope.recurrenceDaysEnum = record.getRecurrenceDaysEnum()

    $scope.cancel = ->
      if Modal.whichModal() is "moveAppt"
        WebTracking.track 'appointment.click.drag-cancel'
      if Modal.whichModal() in ['editAppt', 'createAppt']
        params =
          'was-new-appointment': record.id is 'pseudo'
          'was-patient-selected': record.data.patientSummary?
        WebTracking.track 'appointment.click.cancel', params
      record.revert()
      Modal.close()
      $scope.confirmSave = false
      appt_conflicts.clear()
      rerender()

    $scope.createNewPatient = ->
      Modal.close()
      PatientCreateModalService.launch().then(
        ((data) -> newPatientCreated(data)), (() -> patientCreateCancelled())
      )

    getPatientBalance = (patientSummary) ->
      featureSet.load()
        .then (features) ->
          if($scope.pmEnabled && patientSummary && features["dark-feature.patient-tx-detail"])
            $scope.form.loadingAmounts = true
            PatientBalanceRepository.getBalance(patientSummary.patientId)
            .then (response) -> response.data
            .then(
              (data) ->
                $scope.form.balanceAmount = data.remainingPatientAmount
                $scope.form.loadingAmounts = false
              ->
                $scope.form.loadingAmounts = 'error'
            )

    $scope.$watch(
      -> record.data.patientSummary
      getPatientBalance
    )

    newPatientCreated = (patient) ->
      Modal.open("createAppt")
      record.data.patientSummary = patient
      $scope.data = record.data

    patientCreateCancelled = ->
      Modal.open("createAppt")

    $scope.rerender = rerender = ->
      Appts.emit 'update'

    unsub.add appt_conflicts.if 'load', ->

      $timeout(->
        max = appt_conflicts.data.length
        max = max_conflicts if max > max_conflicts
        list = appt_conflicts.filterSameAppointment(record)

        $scope.conflicts = list[0 ... max_conflicts]
        $scope.hasConflicts = appt_conflicts.hasConflicts(record, list)
        $scope.hasNonApptConflicts = appt_conflicts.hasNonApptConflicts()

        $scope.loadingConflicts = false

      , TIMEOUT__LOADER_CLOSE_DELAY)

    $scope.findConflicts = ->
      if appt_conflicts.canCheck(record)
        $scope.loadingConflicts = true
        appt_conflicts.findConflicts(record)

    $scope.selectPatient = ->
      if $scope.typeaheadSelectedPatient?
        record.data.patientSummary = $scope.typeaheadSelectedPatient
        rerender()

    $scope.apptReasonChange = ->
      sec = Prefs.increment
      if reason = record.reason()
        sec = reason.data.duration * 60

      record.length sec # set length of the record
      form.duration = sec / 60 # set minutes value in the box

      $scope.findConflicts()

      rerender()

    $scope.durationChange = ->
      record.length form.duration * 60
      $scope.findConflicts()
      rerender() if form.duration

    $scope.dateTimeChange = (callback) ->
      if /\d{4}-\d{2}-\d{2}/.test(form.date)
        split = form.date.split('-')
        form.date = split[1] + '/' + split[2] + '/' + split[0]

      m_time = moment(form.date + ' ' + form.time, 'MM/DD/YYYY h:mma')
      m_a = m_time.toArray()

      # this is a hack fix. attempting to set a moment tz object to a specific
      # time does not actually work as expected with timezones. While the
      # timezone is respected that actual time set is not.
      m_time = m_time.tz(Prefs.tz)
      .year(m_a[0])
      .month(m_a[1])
      .date(m_a[2])
      .hours(m_a[3])
      .minutes(m_a[4])
      .seconds(m_a[5])
      .milliseconds(m_a[6])

      $timeout ->
        record.startTime m_time.unix()

        rerender()

        $scope.findConflicts()
        callback() if callback?
      , 1

    $scope.recurrenceDateChange = ->
      record.data.recurrenceRule ?= {}

      $timeout ->
        record.data.recurrenceRule.endDate =
          timez.zoneSafe(form.recurrencedate, date_f).unix() * 1000

        $scope.findConflicts()
      , 1

    $scope.setLimitView = (to) ->
      form.limit = to
      form.recurrencedate = ''
      record.data.recurrenceRule?.endDate = null
      record.data.recurrenceRule?.numberOfTimes = null

    $scope.resetPatient = ->
      record.revert 'patientSummary'
      $scope.nameSearch = ''

    form_validate = (submitted_form) ->
      if record.saving or (submitted_form and not submitted_form.$valid)
        return false

      if record.data.recurring and not record.unhandledRecurrence
        unless rule = record.data.recurrenceRule
          return false

        unless rule.dayOfWeekFlags
          return false

        if form.limit is 'end-date'
          if rule.endDate < $scope.endDateMinimum and
          rule.endDate isnt record.saved.recurrenceRule?.endDate
            return false

      true

    $scope.showConfirmed = (submitted_form) ->
      logger.trace 'setting confirmation', 'appt id', record.id

      form.submitted = true
      return unless form_validate submitted_form

      if not record.changed() && record.id != 'pseudo'
        logger.trace 'nothing to save. closing modal.'
        $scope.cancel()
        return

      if !record.changed('recurrenceRule') and !record.changed('recurring') and
      record.id != 'pseudo'
        logger.trace 'opening confirmation.'
        $scope.confirmSave = true
      else if !record.data.deleted
        logger.trace 'no confirmation needed. Saving.'
        $scope.save(submitted_form)

    cut_series = (record) ->
      appts = Appts.findBy 'appointmentId', record.data.appointmentId
      for appt in appts or []
        Appts.cut appt
      return

    $scope.checkRecurrenceDays = (html_form) ->
      data = $scope.record.data
      valid = !!(not data.recurring or data.recurrenceRule.dayOfWeekFlags)
      html_form.$setValidity 'dayOfWeekFlags', valid
      if html_form.$valid
        $scope.findConflicts()

    $scope.save = (submitted_form) ->

      if Modal.whichModal() is "moveAppt"
        WebTracking.track 'appointment.click.drag-confirm'

      form.submitted = true
      return unless form_validate submitted_form

      form.servicesubmitted = true

      consolidate = Async::consolidate (err) ->
        if err
          console.error err
          alert 'Save error\nPlease refresh and try again'

        if new_appt
          Appts.setPseudo()

        if recurrence_rule_changed or form.series isnt 'occurrence'
          if new_appt
            # needs to remove appt that came back in a wierd way
            # (has recurrence rule, but no occurance id - hence not upsertable
            # based on id)
            for appt in Appts.data
              if appt.data.occurrenceId is null and appt.data.recurrenceRule
                Appts.cut appt
                break
          else
            cut_series record
          Appts.clearCache()
          load_sub = Appts.on1 'load', 'load-error', ->
            load_sub()
            rerender()
            Modal.close()
            form.servicesubmitted = false
          return Appts.loadRange preload_range...
        else
          rerender()
          Modal.close()
          form.servicesubmitted = false

      data = record.data
      recurrence_rule_changed = record.changed 'recurrenceRule', 'recurring'

      Appts.cut record
      if record.id isnt "pseudo" and data.recurring
        if form.series is "series" or recurrence_rule_changed
          data.occurrenceId = null

      new_appt = record.id is 'pseudo'

      Appts.save record, (err) ->
        consolidate err

    $scope.viewPatientRecord = () ->
      if(featureSet.hasClinicalFeatures())
        location = UrlFor.ehrFacesheet(record.data.patientSummary.patientId)
      else
        location = UrlFor.ehrDemographics(record.data.patientSummary.patientId)

      message = "There are unsaved changes that will be lost if you" +
        " navigate away. Are you sure you would like to continue?"

      if $scope.editForm.$dirty
        if confirm(message)
          window.location = location
      else
        window.location = location

    $scope.cacheForm = (form) ->
      $scope.editForm = form

    $scope.delete = ->
      form.submitted = true
      form.servicesubmitted = true

      finished = (err) ->
        if err
          console.error err
          alert 'Delete error\nPlease refresh and try again'
        rerender()
        Modal.close()
        form.servicesubmitted = false

      data = record.data
      if data.recurring and form.series is 'occurrence'
        Appts.cut record
        rec_exc = new RecurrenceException()
        rec_exc.save data.appointmentId, data.occurrenceId, finished
      else
        Appts.delete record, (err) ->
          if data.recurring
            cut_series record
          finished err
    
    $scope.getPhoneLabel = ->
      phoneLabel = ''
      patientSummary = record.data.patientSummary
      preferredType = patientSummary.preferredPhoneType
      if preferredType and patientSummary[preferredType.toLowerCase()+'Phone']
        phoneLabel = preferredType
      else
        for key in ['Mobile', 'Home', 'Work', 'Other']
          if patientSummary[key.toLowerCase() + 'Phone']
            phoneLabel = key
      phoneLabel = phoneLabel.toLowerCase()
      phoneLabel[0].toUpperCase() + phoneLabel.slice(1)

    $scope.getPatientPreferredPhoneNo = ->
      phoneLabel = $scope.getPhoneLabel()
      return '' if not phoneLabel
      key = phoneLabel.toLowerCase() + 'Phone'
      record.data.patientSummary[key] or ''

    updateMinRecurrenceDate = ->
      date = DateConverter::parsePickerFormat form.date
      date.setSeconds( date.getSeconds() + ONE_DAY_SECONDS )
      m = date.valueOf()
      if form.recurrencedate?
        eDate = DateConverter::parsePickerFormat form.recurrencedate
      if not $scope.minRecurrenceEndDate? or
      m > $scope.minRecurrenceEndDate or
      (eDate? and m > eDate.valueOf())
        $scope.minRecurrenceEndDate = m
        if form.recurrencedate? and form.recurrencedate isnt ''
          form.recurrencedate = ''

    $scope.$watch 'form.date', ->
      updateMinRecurrenceDate()

    $scope.changePatient = ->
      $scope.record.data.patientSummary = null

    create_or_edit = (appt) ->
      $scope.timeslots ?= DateConverter::getTimeSlots Prefs.increment / 60

      if appt? and appt.id isnt 'pseudo'
        appt.loadRecurringHead()

      unless $scope.lens?.length
        $scope.lens = []
        for i in [1 .. 6] when i isnt 5
          $scope.lens.push
            sec: Prefs.increment * i
            min: Prefs.increment * i / 60

      record = $scope.record = appt

      $scope.data = record.data

      $scope.selectedProOrRsc = record.pro?()?.xid

      $scope.recurrenceDaysEnum = record.getRecurrenceDaysEnum()

      form.time = (t = record.startTime()).format time_f
      form.date = t.format date_f
      form.series = 'occurrence'

      if record.data.recurrenceRule?.numberOfTimes
        form.limit = 'visit'
      else if record.data.recurrenceRule?.endDate
        form.limit = 'end-date'

      $timeout ->
        if Locations.data.length is 1
          record.data.serviceLocationId = Locations.data[0].id
        if record.data?.recurrenceRule?.endDate?
          form.recurrencedate = timez(record.data.recurrenceRule.endDate)
          .utc().format date_f
      , 333

      form.duration = record.length() / 60

      rerender()

    create_or_edit Modal.record

]
