
CalendarSetupCtrl.controller 'CalendarSetupOfficeHoursCtrl', [
  '$http', '$location', 'Locations', 'OfficeHr', 'OfficeHrs', 'Prefs', 'Pros',
  '$q', 'Resource', 'Resources', '$rootScope', '$routeParams', '$scope'
  ($http, $location, Locations, OfficeHr, OfficeHrs, Prefs, Pros, $q, Resource,
   Resources, $rootScope, $routeParams, $scope) ->

    #hide chrome
    $rootScope.hideChrome = true

    # event unsubscriber
    unsub = Locations.unsubscriber()

    parse_ms_in_day = DateConverter::parseMsInDay

    # unsubscribe from listeners when controller gets pulled
    $scope.$on '$destroy', ->
      delete $rootScope.hideChrome
      unsub()

    # day setup
    createDay = (name, dayOfWeek) ->
      {name: name, dayOfWeek: dayOfWeek, slots: [], breaks: []}

    MONDAY = createDay(DayOfWeek.NAMES.MONDAY, DayOfWeek.MONDAY)
    TUESDAY = createDay(DayOfWeek.NAMES.TUESDAY, DayOfWeek.TUESDAY)
    WEDNESDAY = createDay(DayOfWeek.NAMES.WEDNESDAY, DayOfWeek.WEDNESDAY)
    THURSDAY = createDay(DayOfWeek.NAMES.THURSDAY, DayOfWeek.THURSDAY)
    FRIDAY = createDay(DayOfWeek.NAMES.FRIDAY, DayOfWeek.FRIDAY)
    SATURDAY = createDay(DayOfWeek.NAMES.SATURDAY, DayOfWeek.SATURDAY)
    SUNDAY = createDay(DayOfWeek.NAMES.SUNDAY, DayOfWeek.SUNDAY)

    $scope.days = [MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY,
                   SUNDAY]

    ##
    # loading methods
    ##
    decorateOfficeHr = (officeHr) ->
      data = officeHr.data
      officeHr.start = DateConverter::formatTimeOfDayFromMS data.startTime
      officeHr.incomplete = false
      officeHr.invalid = false
      if officeHr.data.officeHrsCategory is 2
        duration = data.endTime - data.startTime
        durMin = duration / MS_IN_MINUTE
        officeHr.duration = DateConverter::formatDurationFromMinutes(durMin)
      else
        officeHr.end = DateConverter::formatTimeOfDayFromMS data.endTime
      officeHr

    loadOfficeHours = ->
      if $scope.isStaffMember
        type = 'resourceId'
      else
        type = 'providerId'
      officeHrs = OfficeHrs.findBy(type, $scope.targetId) or []
      blankWeekDays()
      for officeHr in officeHrs
        dayIndex = officeHr.data.dayOfWeek - 1
        decorateOfficeHr(officeHr)
        if(officeHr.data.officeHrsCategory is 1)
          $scope.days[dayIndex].slots.push(officeHr)
        else
          $scope.days[dayIndex].breaks.push(officeHr)

      sorter = (a, b) ->
        a.saved.startTime > b.saved.startTime

      for day in $scope.days
        day.slots.sort sorter
        day.breaks.sort sorter

      return

    loadProvider = (callback) ->
      unsub.add Pros.if 'load', 'update', ->
        pro = Pros.findBy('providerId', $scope.targetId)
        if pro?.length
          $scope.resource = new Resource
          $scope.resource.data.resourceName = pro[0].fullName()
        else
          console.error('Provider load ERROR for target: ' + $scope.targetId)
        callback()
        return

    loadStaff = (callback) ->
      unsub.add Resources.if 'load', 'update', ->
        $scope.staff = Resources.findByResourceType 'staff'
        staff = Resources.findBy('resourceId', $scope.targetId)
        if staff?.length
          $scope.resource = new Resource( staff[0].data )
          dirtyWatcher = $scope.$watch 'resource.data.resourceName', (o, n)->
            return unless o isnt n
            $scope.workStatus.dirty = true
            dirtyWatcher()
        else
          console.error('Staff load ERROR for target: ' + $scope.targetId)
        callback()
        return

    ##
    ## methods
    ##

    ##
    # Create office hours for use within the unit of work.  Office hours
    # are records but also contain extra state information used to manage
    # their lifecycle within the user interface (invalid, incomplete, etc.)
    ##
    setupOfficeHr = (officeHr = new OfficeHr, category)->
      officeHr.invalid = false
      officeHr.incomplete = true
      if category? and category is 2
        if not officeHr.data.label
          officeHr.data.label = 'Break'
        officeHr.data.officeHrsCategory = 2
      else
        officeHr.data.officeHrsCategory = 1
      if officeHr.data.officeHrsCategory is 1
        if Locations.data.length is 1
          officeHr.data.serviceLocationId = Locations.data[0].id
      officeHr

    ##
    # help functions for the day
    ##
    blankDay = (day)->
      while day.slots.length
        o = day.slots.pop()
        if o.id?
          $scope.officeHrsToDelete.push o.id
      while day.breaks.length
        o = day.breaks.pop()
        if o.id?
          $scope.officeHrsToDelete.push o.id

    blankWeekDays = ->
      blankDay day for day in $scope.days if $scope.days?

    defaultDay = (day) ->
      slot = setupOfficeHr()
      slot.start = '9:00am'
      slot.end = '5:00pm'
      slot.data.startTime = parse_ms_in_day slot.start
      slot.data.endTime = parse_ms_in_day slot.end
      slot.data.dayOfWeek = day.dayOfWeek
      slot.incomplete = not slot.data.serviceLocationId?
      day.slots.push slot

      brk = setupOfficeHr(new OfficeHr, 2)
      brk.start = '12:00pm'
      brk.duration = '1hr'
      brk.data.dayOfWeek = day.dayOfWeek
      brk.data.startTime = parse_ms_in_day brk.start
      brk.data.endTime = brk.data.startTime + DateConverter::parseDurMS(
        brk.duration)
      brk.incomplete = false
      day.breaks.push brk

    defaultWeekDays = ->
      result = confirm('This will remove all existing Office Hours and apply ' +
        'default Office Hours for the week. Would you like to continue?')
      if result
        $scope.workStatus.dirty = true
        blankWeekDays()
        if $scope.days?
          defaultDay day for day in $scope.days when day.name not
            in [DayOfWeek.NAMES.SATURDAY, DayOfWeek.NAMES.SUNDAY]
      weekInvalid()

    ##
    # validate week
    ##
    weekInvalid = ->
      for day in $scope.days
        for o in day.slots
          if o._invalid
            $scope.workStatus.invalid = true
            return false
        for o in day.breaks
          if o.incomplete or o.invalid
            $scope.workStatus.invalid = true
            return false
      $scope.workStatus.invalid = false
      true

    decorateIncompleteFinish = ->
      for day in $scope.days
        for o in day.slots
          if o.incomplete
            o.incompleteFinish = true
        for o in day.breaks
          if o.incomplete
            o.incompleteFinish = true
      return

    ##
    # dirty checking
    ##
    backToSetup = ->
      if $scope.workStatus.dirty
        result = confirm('There are unsaved changes that will be lost if ' +
          'you navigate away, are you sure you would like to continue?')
        if result
          $location.path('/calendar-setup').search('view', 'office-hours')
      else
        $location.path('/calendar-setup').search('view', 'office-hours')

    ##
    # slots
    ##
    check_day_slots = (day) ->
      overlap = (a, b) ->
        beg1 = parse_ms_in_day a.start
        beg2 = parse_ms_in_day b.start
        end1 = parse_ms_in_day a.end
        end2 = parse_ms_in_day b.end

        if beg1 >= end1 or beg2 >= end2
          return false

        beg1 < beg2 < end1 or beg1 < end2 < end1 or
        beg2 < beg1 < end2 or beg2 < end1 < end2 or
        beg1 is beg2 or end1 is end2

      has_conflict = (list, i) ->
        for item, ii in list when ii isnt i
          if overlap list[i], item
            return true
        false

      list = (slot for slot in day.slots).reverse()
      day._conflict = false
      for slot, i in list
        start     = slot.start
        end       = slot.end
        complete  = start? and end?
        order_err = complete and parse_ms_in_day(start) >= parse_ms_in_day(end)
        slot._error =
          location: not slot.data.serviceLocationId?
          partial:  not complete
          start:    not start?
          end:      not end?
          order:    order_err
          conflict: not order_err and has_conflict list, i

        day._conflict = day._conflict or slot._error.conflict

        slot._invalid = !!(v for k, v of slot._error when v).length
      return

    slotDataChange = (day, slot, slotIndex) ->
      $scope.workStatus.dirty = true
      check_day_slots day

      unless slot._invalid
        slot.data.startTime = parse_ms_in_day slot.start
        slot.data.endTime   = parse_ms_in_day slot.end
        slot.data.dayOfWeek = day.dayOfWeek
      weekInvalid()

    removeSlot = (day, slotIndex) ->
      $scope.workStatus.dirty = true
      if day.slots[slotIndex].id?
        $scope.officeHrsToDelete.push(day.slots[slotIndex].id)
      day.slots.splice(slotIndex, 1)
      for slot, i in day.slots
        slotDataChange(day, slot, i)
      weekInvalid()

    ##
    # breaks
    ##
    isIncompleteBreak = (brk) ->
      label = brk.data.label?.replace /^\s+|\s+$/g, ""
      if label and brk.duration? and brk.start?
        delete brk.labelError
        return false
      if not label
        brk.labelError = true
      else
        delete brk.labelError
      true

    breakOverlaps = (existing, add) ->
      return false if isIncompleteBreak(existing) or existing.invalid
      addStart = add.data.startTime
      addEnd = add.data.endTime
      existingStart = existing.data.startTime
      existingEnd = existing.data.endTime
      return true if existingEnd > addStart and addEnd > existingStart
      false

    validateNewBreakForDay = (day, brk, index) ->
      if day.breaks.length is 1
        return true
      for s, i in day.breaks when index isnt i
        invalid = breakOverlaps(s, brk)
        break if invalid
      brk.invalid = invalid

    breakChange = (day, brk, brkIndex) ->
      $scope.workStatus.dirty = true
      if brk.incomplete
        brk.incomplete = isIncompleteBreak brk
        return weekInvalid() if brk.incomplete
      brk.data.startTime = parse_ms_in_day brk.start
      brk.data.endTime = brk.data.startTime + DateConverter::parseDurMS(
        brk.duration)
      brk.data.dayOfWeek = day.dayOfWeek
      brk.invalid = isIncompleteBreak(brk)
      return weekInvalid() if brk.invalid
      validateNewBreakForDay(day, brk, brkIndex)
      delete brk.incompleteFinish
      weekInvalid()

    removeBreak = (day, breakIndex) ->
      $scope.workStatus.dirty = true
      if day.breaks[breakIndex].id?
        $scope.officeHrsToDelete.push(day.breaks[breakIndex].id)
      day.breaks.splice(breakIndex, 1)
      weekInvalid()

    ##
    # Update office hours
    ##
    prepOfficeHrSlot = (day, officeHr) ->
      if not $scope.isStaffMember
        officeHr.data.providerId = Number($scope.targetId)
        officeHr.data.resourceId = 0
      else
        officeHr.data.resourceId = Number($scope.targetId)
        officeHr.data.providerId = 0

    ##
    # Action entry point for saving the unit of work
    ##
    updateOfficeHours = ->

      unless $scope.resource.data.resourceName
        alert "Please provide a staff name"
        return

      # for now, just skip any work if we are invalid
      if $scope.workStatus.invalid
        decorateIncompleteFinish()
        return

      updatePayload = {}

      if $scope.isStaffMember and $scope.resource?.changed()
        updatePayload.resource = $scope.resource.entity()

      if $scope.officeHrsToDelete.length
        updatePayload.deleteOfficeHrIdsList = $scope.officeHrsToDelete

      changed = []

      for day in $scope.days
        changed.push (slot for slot in day.slots when slot.changed())...
        changed.push (brk for brk in day.breaks when brk.changed())...

      ## prep payload
      allOfficeHours = []
      for o in changed
        prepOfficeHrSlot(day, o)
        allOfficeHours.push o.entity()
      updatePayload.officeHrsList = allOfficeHours

      ## save all
      OfficeHrs.saveAll updatePayload, ( data ) ->
        if $scope.isStaffMember and $scope.resource?.changed()
          Resources.upsert data.resource
        OfficeHrs.reload null, ->
          $location.path('/calendar-setup').search('view', 'office-hours')

    ##
    # scope
    ##
    $scope.backToSetup = backToSetup
    $scope.isStaffMember = $routeParams.type is '1'
    $scope.targetId = $routeParams.id
    $scope.locations = []
    $scope.officeHrsToDelete = []
    $scope.workStatus = {invalid: false, dirty: false}

    # functions
    $scope.blankWeekDays = ->
      result = confirm('This will remove all existing Office Hours. ' +
        'Would you like to continue?')
      if result
        $scope.workStatus.dirty = true
        blankWeekDays()
      weekInvalid()

    $scope.defaultWeekDays = defaultWeekDays
    $scope.updateOfficeHours = updateOfficeHours

    # slots
    $scope.slotDataChange = slotDataChange
    $scope.addSlot = (day) ->
      day.slots.push(setupOfficeHr())
      weekInvalid()
    $scope.removeSlot = removeSlot

    # breaks
    $scope.addBreak = (day) ->
      day.breaks.push(setupOfficeHr(new OfficeHr, 2))
      weekInvalid()
    $scope.removeBreak = removeBreak
    $scope.breakChange = breakChange

    ##
    # execute the controller
    ##

    # time slots for the page
    unsub.add Prefs.if1 'load', ->
      # including next mindnight
      $scope.timeSlots = DateConverter::getTimeSlots Prefs.incrementMinute, true

    # locations
    unsub.add Locations.if 'load', 'update', ->
      $scope.locations.pop() while $scope.locations.length
      for loc in Locations.data
        $scope.locations.push({
          id: loc.data.serviceLocationId, name: loc.data.name})
      return

    # load a provider or staff if required
    if $scope.targetId? and $scope.targetId isnt '0'
      load = ->
        unsub.add OfficeHrs.if 'load', ->
          loadOfficeHours()
        OfficeHrs.clear()
        OfficeHrs.load()
      if not $scope.isStaffMember
        loadProvider(load)
      else
        loadStaff(load)
    else
      newResource = {resourceTypeId: 3}
      $scope.resource = new Resource(newResource)
      dirtyWatcher = $scope.$watch 'resource.data.resourceName', (o, n)->
        return unless o isnt n
        $scope.workStatus.dirty = true
        dirtyWatcher()

]
