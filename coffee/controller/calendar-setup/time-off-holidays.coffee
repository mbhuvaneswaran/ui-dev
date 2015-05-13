
CalendarSetupCtrl.controller 'TimeOffHolidaysCtrl', [
  'CustomHoliday', 'CustomHolidaysMaster', '$http',
  'HolidayInstancesChild' , 'Modal', 'ObservedHolidays',
  'Prefs', 'Pros', '$scope', 'TimeOff', 'TimeOffs', 'timez'
  (CustomHoliday, CustomHolidaysMaster, $http,
   HolidayInstancesChild, Modal, ObservedHolidays,
   Prefs, Pros, $scope, TimeOff, TimeOffs, timez) ->

    time_f = 'h:mma'
    date_f = 'MM/DD/YYYY'
    datetime_f = 'MM/DD/YYYYh:mma'
    INPUT_FORMAT = 'DD-MMM-YY'

    today = new Date().getTime()
    oneYear = today + (60 * 60 * 24 * 364 * 1000)
    $scope.holidayInstances = []
    $scope.providers = Pros.data
    $scope.Pros = Pros
    $scope.customHoliday = {}
    $scope.instanceToRemove
    $scope.today = today

    $scope.oneYearFilter = (instance) ->
      date = moment(instance.data.holidayInstanceDate, INPUT_FORMAT).valueOf()
      return date < oneYear
    $scope.observedHolidays = ObservedHolidays.data

    $scope.vacations = []
    $scope.editTimeOff = {}
    $scope.editTimeOffForm = {}

    # event unsubscriber
    unsub = Prefs.unsubscriber()

    # unsubscribe from listeners when controller gets pulled
    $scope.$on '$destroy', unsub

    # time slots for the page
    unsub.add Prefs.if1 'load', ->
      $scope.timeSlots = DateConverter::getTimeSlots(Prefs.incrementMinute)

    populateVacationData = ->
      empty_array $scope.vacations
      for o in TimeOffs.data
        o.name = o.pro?()?.fullName()
        o.start = timez(o.data.startDateTime).format('MMM D, YYYY')
        o.end = timez(o.data.endDateTime).format('MMM D, YYYY')
        $scope.vacations.push o

    loadTimeOffData = ->
      unsub.add Prefs.if1 'load', ->
        unsub.add Pros.if 'load', ->
          TimeOffs.loadYearAhead populateVacationData
    loadTimeOffData()

    updateHolidayData = ->
      today     = (tz = timez().hour(0).minute(0).second(0)).unix()
      plus1year = tz.year(tz.year() + 1).unix()

      range_filter = (data) ->
        t = timez.zoneSafe(data.holidayInstanceDate, INPUT_FORMAT).unix()
        today <= t <= plus1year

      displayData = []
      for o in HolidayInstancesChild.data when range_filter o.data
        displayData.push o
      for o in CustomHolidaysMaster.data when range_filter o.data
        displayData.push o
      inst = $scope.holidayInstances
      empty_array inst
      displayData.sort (s, e) ->
        a = s.dateValue()
        b = e.dateValue()
        if a < b then return -1
        if a > b then return 1
        0
      for o in displayData
        inst.push o
      return

    unsub.add HolidayInstancesChild.if 'load', updateHolidayData

    ##
    # Methods
    ##
    timeOffInvalid = ->
      timeOff = $scope.editTimeOff
      form = $scope.editTimeOffForm

      timeoff_data = timeOff.data ?= {}
      if (xid = Pros.parseXid timeOff.providerOrResourceId).record
        timeoff_data.providerId = xid.providerId
        timeoff_data.resourceId = xid.resourceId
        timeOff.providerError = false
      else
        timeOff.providerError = true

      reason = timeoff_data.reason?.replace /^\s+|\s+$/g, ""
      if reason
        timeOff.reasonError = false
      else
        timeOff.reasonError = true

      if form.sDate and form.sTime
        timeOff.startDateError = false
      else
        timeOff.startDateError = true

      if form.eDate and form.eTime
        timeOff.endDateError = false
      else
        timeOff.endDateError = true

      unless timeOff.startDateError or timeOff.endDateError
        s = moment(form.sDate + form.sTime, datetime_f)
        e = moment(form.eDate + form.eTime, datetime_f)
        unless e.isAfter(s)
          timeOff.startDateError = true
          timeOff.endDateError = true

      timeOff.providerError or
      timeOff.reasonError or
      timeOff.startDateError or
      timeOff.endDateError

    ##
    # User functions
    ##
    $scope.persistObservedHolidays = ->
      changed = []
      for observed in ObservedHolidays.data
        changed.push observed if observed.changed('observed')
      ObservedHolidays.save changed..., ->
        Modal.close()
        HolidayInstancesChild.reload()

    $scope.saveCustomHoliday = ->
      holiday = $scope.customHoliday
      name = holiday.holidayName?.replace /^\s+|\s+$/g, ""
      if name
        holiday.nameError = false
      else
        holiday.nameError = true
      if holiday.startDate
        holiday.startDateError = false
      else
        holiday.startDateError = true
      if holiday.nameError or holiday.startDateError
        return

      #date management
      h = new CustomHoliday $scope.customHoliday
      d = moment(h.data.startDate, 'MM/DD/YYYY').format('DD-MMM-YY')
      h.data.holidayInstanceDate = d
      CustomHolidaysMaster.save h, ->
        # this is a transient object
        empty_object $scope.customHoliday
        updateHolidayData()
      Modal.close()

    $scope.editTimeOffModal = (timeOff) ->
      $scope.editTimeOff = timeOff
      form = $scope.editTimeOffForm
      form.sTime = (s = timez(timeOff.data.startDateTime)).format time_f
      form.sDate = s.format date_f
      form.eTime = (e = timez(timeOff.data.endDateTime)).format time_f
      form.eDate = e.format date_f
      Modal.open('time-off-modal')

    $scope.removeTimeOff = ->
      TimeOffs.delete $scope.editTimeOff, ->
        populateVacationData()
        $scope.editTimeOff = {}
        $scope.editTimeOffForm = {}
        Modal.close()

    $scope.removeTimeOffModal = ->
      Modal.open('delete-time-off-modal')

    $scope.saveTimeOff = ->
      if timeOffInvalid()
        return
      form = $scope.editTimeOffForm
      if $scope.editTimeOff.timeOffId?
        timeOff = $scope.editTimeOff
      else
        timeOff = new TimeOff $scope.editTimeOff.data
      s = timez.zoneSafe(form.sDate + form.sTime, datetime_f).valueOf()
      e = timez.zoneSafe(form.eDate + form.eTime, datetime_f).valueOf()
      timeOff.data.startDateTime = s
      timeOff.data.endDateTime = e

      TimeOffs.save timeOff, ->
        $scope.editTimeOff = {}
        $scope.editTimeOffForm = {}
        populateVacationData()
        Modal.close()

    $scope.removeInstanceModal = (instance) ->
      $scope.instanceToRemove = instance
      Modal.open('remove-instance-modal')

    $scope.removeInstance = ->
      completion = ->
        updateHolidayData()
        Modal.close()
      inst = $scope.instanceToRemove.data
      if inst.customHolidayId? and inst.customHolidayId isnt 0
        CustomHolidaysMaster.delete($scope.instanceToRemove, completion)
      else
        HolidayInstancesChild.delete($scope.instanceToRemove, completion)

    $scope.cancelTimeOff = ->
      $scope.editTimeOff = {}
      $scope.editTimeOffForm = {}
      Modal.close()

    $scope.cancelHoliday = ->
      empty_object $scope.customHoliday
      Modal.close()

]
