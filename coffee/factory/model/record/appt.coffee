main.factory 'Appt', [
  '$http', 'ApptReasons', 'Prefs', 'Pros', 'Record', 'Resources', 'UrlFor',
  'timez',
  ($http, ApptReasons, Prefs, Pros, Record, Resources, UrlFor,
   timez) ->

    end_time_literal   = 'endTime'
    start_time_literal = 'startTime'

    class Appt extends Record
      api:           'Appt'
      idProperty:    ['appointmentId', 'occurrenceId']
      recurringHead: undefined

      constructor: ->
        super

        # pre-cache non-standard recurrence state
        if @nonWeeklyRecurrence()
          @unhandledRecurrence = true

      _tz: (property, container='data') ->
        time_idx = CACHE_PREFIX + property
        tz_idx   = time_idx + '_tz'
        unless @[time_idx] is t = @[container][property]
          @[time_idx] = t
          @[tz_idx] = timez t
        @[tz_idx]

      getRecurrenceDaysEnum: =>
        for day in [0 .. 6] # Mon .. Sun
          id:   day
          name: moment().day(day + 1).format 'ddd'
          up:  !!((@data.recurrenceRule?.dayOfWeekFlags or 0) & Math.pow 2, day)

      setRecurrenceDay: (day, value, clearAllDays) =>
        rule = (@data.recurrenceRule ?= {})
        rule.dayOfWeekFlags ?= 0
        if clearAllDays
          rule.dayOfWeekFlags = 0
        mod = Math.pow 2, day
        is_up = rule.dayOfWeekFlags & mod
        value = !is_up unless value? # toggle if value is not provided
        unless !!is_up is value
          if value
            rule.dayOfWeekFlags += mod
          else
            rule.dayOfWeekFlags -= mod

      nonWeeklyRecurrence: =>
        unless @data.recurring and
        (rr = @data.recurrenceRule) and typeof rr is 'object'
          return false

        unless rr.dayOfWeekFlags?
          return true

        unless rr.dayInterval in [null, 7]
          return true

        nulls = ['dayOfMonth', 'dayOfWeekMonthlyOrdinalFlags', 'monthInterval',
                 'monthOfYear', 'typeOfDay', 'typeOfDayMonthlyOrdinalFlags']
        for k in nulls when rr[k]?
          return true

        false

      nonRecurringInstance: =>
        instance = @copyData()

        instance.recurrenceRule = null
        instance.occurrenceId = null
        instance.appointmentId = null
        instance.recurring = false

        new Appt instance

      age: =>
        if @_dob
          dob = new Date( @_dob.valueOf() )
          return DateConverter::getYearsOfAge( dob )
        @dob()
        @age()

      dob: =>
        return @_dob.format('MMM D, YYYY') if @_dob
        patient_summary = @data.patientSummary
        dob = new Date patient_summary.dateOfBirth
        dob = timez.zoneSafe [dob.getUTCFullYear(), dob.getUTCMonth() + 1,
                              dob.getUTCDate()].join('-'), 'YYYY-M-D'
        (@_dob = dob).format 'MMM D, YYYY'

      defaultLength: =>
        reason_id = @data.appointmentReasonId
        len = 15 * 60
        if reason_id and reason = ApptReasons.get reason_id
          len = reason.data.duration * 60
        else if increment = Prefs.increment
          len = increment
        @data[end_time_literal] = @data[start_time_literal] + len * 1000

      length: (seconds) =>
        unless seconds?
          unless (end = @data[end_time_literal])?
            @defaultLength()
            end = @data[end_time_literal]
          return (end - @data[start_time_literal]) / 1000

        @data[end_time_literal] = @data[start_time_literal] + seconds * 1000
        return

      savedLength: =>
        if (t1 = @saved[start_time_literal]) and t2 = @saved[end_time_literal]
          (t2 - t1) / 1000

      overlap: (appt) =>
        beg1 = @data[start_time_literal]
        beg2 = appt.data[start_time_literal]
        end1 = @data[end_time_literal]
        end2 = appt.data[end_time_literal]

        beg1 < beg2 < end1 or beg1 < end2 < end1 or
        beg2 < beg1 < end2 or beg2 < end1 < end2 or
        beg1 is beg2 or end1 is end2

      pro: (saved) =>
        target = @[if saved then 'saved' else 'data']
        if target.providerId
          Pros.get target.providerId
        else
          Resources.get target.resourceId

      reason: =>
        ApptReasons.get @data.appointmentReasonId

      name: =>
        patient_summary = @data.patientSummary
        result = patient_summary.lastName + ', ' + patient_summary.firstName
        result += ' ' + patient_summary.middleName if patient_summary.middleName
        result

      endTime: =>
        @_tz end_time_literal

      startTime: (seconds) =>
        # get
        unless seconds?
          return @_tz start_time_literal

        # set
        @data[end_time_literal]   = (seconds + @length()) * 1000
        @data[start_time_literal] = seconds * 1000

      savedStartTime: =>
        @_tz start_time_literal, 'saved'

      duration: ->
        ( @data[end_time_literal] - @data[start_time_literal] ) / 1000 / 60

      savedDuration: ->
        ( @saved[end_time_literal] - @saved[start_time_literal] ) / 1000 / 60

      startDateChanged: =>
        return false unless @changed start_time_literal
        @startTime().format('YYMMDD') isnt @savedStartTime().format 'YYMMDD'

      entity: =>
        # Possible appointmentStatus values: 'Unknown', 'Scheduled',
        #   'ReminderSent','Confirmed', 'CheckedIn', 'Roomed', 'CheckedOut',
        #   'ClaimPending','ClaimSent', 'NoShow', 'Cancelled', 'Rescheduled'
        #   'Tentative'

        data = @data

        value_or_null = (attr) ->
          if (value = data[attr])?
            return Number value
          null

        savable =
          appointmentStatus:   data.appointmentStatus or 1
          appointmentType:     data.appointmentType or 1
          deleted:             data.deleted or false
          createdBy:           -1
          endTime:             Number data.endTime
          notes:               data.notes
          providerId:          value_or_null 'providerId'
          resourceId:          value_or_null 'resourceId'
          resourceIds:         data.resourceIds or []
          recurrence:          data.recurring or false
          recurring:           data.recurring or false
          occurrenceId:        data.occurrenceId
          startTime:           Number data.startTime
          updatedBy:           -1

        if typeof (resource_ids = savable.resourceIds) is 'object' and
        not Array.isArray? resource_ids
          arr = []
          i = 0
          while typeof resource_ids[i] isnt 'undefined'
            arr.push resource_ids[i]
            i += 1
          savable.resourceIds = arr

        # optional numbers
        for field in ['appointmentReasonId', 'serviceLocationId']
          if (v = data[field])?
            savable[field] = Number v

        if data.patientSummary?
          savable.patientSummary = patientId: data['patientSummary'].patientId

        if (id = data.appointmentId) > 1 or id is 1 # must be a number
          savable.appointmentId = id

        if data.recurring
          rr = savable.recurrenceRule = {}
          for k, v of rule = data.recurrenceRule
            rr[k] = v
          unless rr.startDate
            rr.startDate = data.startTime
          else if (not data.occurrenceId and data.recurrenceRule) and
          @recurringHead?.startTime
            savable.startTime = @recurringHead.startTime
            if (delta = @saved.startTime - data.startTime) and not isNaN delta
              savable.startTime -= delta
            savable.endTime = @recurringHead.endTime
            if (delta = @saved.endTime - data.endTime) and not isNaN delta
              savable.endTime -= delta

          if rule.numberOfTimes
            savable.recurrenceRule.numberOfTimes = Number rule.numberOfTimes
          else if rule.endDate
            savable.recurrenceRule.endDate = rule.endDate

        savable

      # log
      save: (callback) =>
        console.error 'depricated use of save method'
        save_cb = (err) =>
          @revert() if err
          callback? err

        if (id = @data.appointmentId) > 1 or id is 1
          super @entity(), id, save_cb
        else
          super @entity(), save_cb

      # if an appointment is recurring, we'll first have to create an
      # appt instance, and then delete that delete that instance
      # log
      delete: (callback) =>
        console.error 'depricated use of delete method'
        appointmentId = @data.appointmentId

        url = UrlFor.api('Appt') + appointmentId

        req = $http.delete url

        req.success (data) =>
          @saving = false
          callback?()

      loadRecurringHead: (callback) =>
        if @recurringHead is undefined
          @recurringHead = null # pending
          url = UrlFor.api('Appt') + @data.appointmentId
          req = $http.get url
          req.error (err) =>
            @recurringHead = false # error
            callback? err
          req.success (data) =>
            @recurringHead = data
            callback? null, data
]
