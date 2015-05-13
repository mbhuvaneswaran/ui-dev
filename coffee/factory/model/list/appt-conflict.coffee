
main.factory 'ApptConflict', [
  'Appts', 'Appt', 'ApptStatus', 'List', 'UrlFor', 'timez'
  (Appts, Appt, ApptStatus, List, UrlFor, timez) ->

    class ApptConflict extends List
      api:          'ApptConflict'
      listProperty: 'appointments'
      recordClass:  Appt
      sortBy:
        property: 'startTime'
        type:     'number'

      constructor: ->
        super

      clear: ->
        empty_array(@data)
        @onBreak = @onHoliday = @outsideOfficeHours = false

      isSameAppt : (appt, appt_check) ->
        if ( appt.data.recurring and appt_check.data.recurring ) or
        ( appt.data.recurring and !appt.saved.recurring ) or
        ( !appt.data.recurring and appt.saved.recurring )
          return appt.data.appointmentId is appt_check.data.appointmentId
        else
          return appt.id is appt_check.id

      filterSameAppointment : (appt, appts) ->
        appts = @data unless appts

        list = []
        for _appt in appts
          if !@isSameAppt(appt, _appt)
            list.push _appt

        list

      # check to see if the given appt has the right data to check against
      # conflicts. New Appts may not have a duration/end date yet, for instance.
      canCheck : (appt) ->
        d = appt.data
        duration = d.endTime - d.startTime

        !!( ( d.providerId or d.resourceId ) and d.endTime and
        !isNaN(d.endTime) and d.startTime and !isNaN(d.startTime) ) and
        duration > 0

      # checks whether or not the last request has conflicts
      # filter_appt - (optional) - if passed, will filter out the appt from the
      #    conflict check. Used to remove appt that we're checking against
      # list - (optional) - if passed, will check against that list instead.
      #    Mostly for performance reasons.
      hasConflicts : (filter_appt, list) ->
        if filter_appt
          list = @filterSameAppointment( filter_appt, @data ) unless list
        else
          list = @data

        list?.length > 0 or @hasNonApptConflicts()

      hasNonApptConflicts : ->
        @onBreak or
        @onHoliday or
        @onTimeOff or
        @outsideOfficeHours

      getPayload : (appt) ->
        data = appt.data
        start_date = appt.startTime()
        start_date_unix = start_date.unix() * 1000
        duration = data.endTime - data.startTime
        d = {}

        # required
        d['providerId'] = data.providerId if data.providerId
        d['resourceId'] = data.resourceId if data.resourceId
        d['duration'] = duration
        d['minCalendarDate'] = start_date_unix
        d['maxAppointmentConflictResults'] = 20
        d['startTimeOfDay'] = start_date.secOfUtcDay() * 1000

        # recurring appt options
        if data.recurring
          rr = data.recurrenceRule

          d['ignoredAppointmentId'] = rr.appointmentId if rr.appointmentId
          d['maxCalendarDate'] = rr.endDate if rr.endDate and !rr.numberOfTimes
          d['ruleDayInterval'] = rr.dayInterval if rr.dayInterval
          d['ruleMonthInterval'] = rr.monthInterval if rr.monthInterval
          d['ruleMonthOfYear'] = rr.monthOfYear if rr.monthOfYear
          d['ruleDayOfMonth'] = rr.dayOfMonth if rr.dayOfMonth
          d['ruleTypeOfDay'] = rr.typeOfDay if rr.typeOfDay
          d['ruleDayOfWeekFlags'] = rr.dayOfWeekFlags if rr.dayOfWeekFlags
          d['ruleNumberOfTimes'] = rr.numberOfTimes if rr.numberOfTimes
        else
          d['maxCalendarDate'] = start_date_unix + duration

        d

      findConflicts : (appt) ->
        conflicts = []

        payload = @getPayload(appt)

        url = UrlFor.api('ApptConflict', payload)

        @clear()
        @load url, (err, data) =>
          @onBreak = data.onBreak
          @onHoliday = data.onHoliday
          @onTimeOff = data.onTimeOff
          @outsideOfficeHours = data.outsideOfficeHours

]
