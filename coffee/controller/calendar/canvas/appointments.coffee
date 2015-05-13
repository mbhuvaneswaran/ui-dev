
CalendarCanvasCtrl.controller 'AppointmentsCtrl', [
  '$scope', '$timeout', 'Appts', 'ApptStatus', 'Locations', 'Modal', 'Prefs',
  'Pros', 'Resources', 'View', 'WebTracking'
  ($scope, $timeout, Appts, ApptStatus, Locations, Modal, Prefs,
   Pros, Resources, View, WebTracking) ->

    VERTICAL_MIN_APPTS = 50

    allowed_appt_types = [0, 1, 3]

    appts = $scope.appts = []
    last_view = View.view

    render_range = View.range.render

    pending_hovered = unhover_promise = null
    $scope.hover = (appt) ->
      pending_hovered = appt
      unless $scope.Pointer?.dragging
        if appt
          $timeout.cancel unhover_promise
          Appts.hovered = appt
        else
          unhover_promise = $timeout ->
            Appts.hovered = null
          , 10

    $scope.hoverResizer = (appt, direction) ->
      unless $scope.Pointer?.dragging
        Appts.hoveredResizer   = appt
        Appts.resizerDirection = direction

    $scope.minuteLength = (appt) ->
      Math.round(appt?.length() / 60) + ' min'

    $scope.$on 'Pointer::drag', (event, delta_x, delta_y, x, y) ->
      resize = (appt, start, length) ->
        appt.startTime(start) if start?
        appt.length length
        appt.resizing = true
        render()

      if (appt = Appts.hovered) and not appt._origAppt and
      View.mouseInSlider and x and y and not View.readOnlyProvider
        {pro, sec} = View.posInfo x, y
        start = appt.data.startTime / 1000

        if Appts.hoveredResizer?.id is appt.id # resize
          if Appts.resizerDirection in ['left', 'top']
            if start isnt sec
              resize appt, sec, appt.length() + start - sec
          else # bottom or right
            sec += Prefs.increment
            if appt.length() + start isnt sec
              resize appt, null, Math.max Prefs.increment, sec - start
        else # move
          if pro and (start isnt sec or appt.pro?()?.xid isnt pro.xid)
            appt.data.providerId = pro.data.providerId or null
            appt.data.resourceId = pro.data.resourceId or null
            appt.startTime sec
            appt.grabbed = true
            render()

    $scope.$on 'Pointer::dragEnd', ->
      return if View.readOnlyProvider

      if appt = Appts.hovered
        appt.grabbed = false
        if appt.changed 'startTime', 'providerId', 'resourceId'
          WebTracking.track 'calendar.interaction.appointment-dragged',
            'calendar-type':View.view
          $scope.modalEdit 'move', appt
      if appt = Appts.hoveredResizer
        appt.resizing = false
        Appts.hoveredResizer = null
        if appt.changed 'endTime', 'startTime'
          WebTracking.track 'calendar.interaction.appointment-resized',
            'calendar-type':View.view
          $scope.modalEdit 'resize', appt
      Appts.hovered = pending_hovered

    $scope.$on 'Pointer::click', ->
      if not View.readOnlyProvider and (appt = Appts.hovered)
        # click tracking
        WebTracking.track 'calendar.interaction.edit-appointment',
          'calendar-type': View.view
        $scope.modalEdit 'edit', appt._origAppt or appt

    render = ->
      return unless $scope.calendarReady and Appts.hasLoaded

      if last_view isnt View.view
        empty_array appts
        last_view = View.view

      em_px     = View.emPx
      week_view = View.view is CALENDAR__VIEW__WEEK

      if View.type is CALENDAR__VIEW__VERTICAL
        slider = $scope.slider()
        visible_start = slider.scrollTop * View.pxSec
        visible_span  = (slider.offsetHeight - 2 * View.emPx) * View.pxSec

      view_filter = (appt) ->
        data = appt.data

        unless data.startTime < render_range[1] * 1000 and
        data.endTime > render_range[0] * 1000 and
        appt.data.appointmentType in allowed_appt_types
          return false

        unless Locations.get(data.serviceLocationId)?.visible
          return false

        if week_view
          unless appt.pro?()?.xid is Pros.selectedProviderId or
          (not appt.data.providerId and
           appt.data.resourceId is Resources.selectedResourceId)
            return false
          day = (appt.startTime().day() + 6) % 7
          unless View.days[day]?.visible
            return false
          appt.day = View.days[day]
        else
          unless appt.pro?()?.visible
            return false

        delete appt.level
        delete appt.levels

        true

      overlap_filter = (appt1, appt2) ->
        return false unless appt2.level?

        if week_view
          unless appt1.day.id is appt2.day.id
            return false
        else
          unless appt1.pro?()?.xid is appt2.pro?()?.xid
            return false

        appt1.id isnt appt2.id and appt1.overlap appt2

      current_appts_map = {}
      current_appts_map[appt.id] = i for appt, i in appts
      new_appts_map = {}

      if View.type is CALENDAR__VIEW__VERTICAL
        prefiltered = []
        for appt in Appts.data
          slices = View.daySlice appt
          for slice in slices when view_filter slice
            prefiltered.push slice
      else
        prefiltered = (appt for appt in Appts.data when view_filter appt)

      if View.type is CALENDAR__VIEW__VERTICAL
        sorted = ({appt} for appt in prefiltered)

        cut = [Math.max(0, visible_start - visible_span)
               Math.min(ONE_DAY_SECONDS, (visible_start + visible_span * 2))]

        for info in sorted
          data = info.appt.data

          t0 = (data.startTime / 1000 - render_range[0]) % ONE_DAY_SECONDS
          t1 = (data.endTime / 1000 - render_range[0]) % ONE_DAY_SECONDS

          if t1 >= cut[0] and t0 < cut[1] or (t0 < cut[0] and t1 >= cut[1])
            info.diff = 0
          else if t1 < cut[0]
            info.diff = cut[0] - t1
          else
            info.diff = t0 - cut[1]

        sorted.sort (a, b) ->
          a.diff - b.diff

        while (ln = sorted.length) > VERTICAL_MIN_APPTS and sorted[ln - 1].diff
          info = sorted.pop()
          if (idx = prefiltered.indexOf info.appt) > -1
            prefiltered.splice idx, 1

      for appt, i in prefiltered
        new_appts_map[appt.id] = true
        if (idx = current_appts_map[appt.id])?
          appts[idx] = appt # ensure updating to new object if replaced
        else
          appts.push appt

        appt.focusDiff = Math.abs View.time % 86400 -
                                  Math.floor appt.data.startTime / 1000 % 86400

      for id, i of current_appts_map
        unless new_appts_map[id]
          appts[i] = null

      clear_end = ->
        while appts.length and appts[appts.length - 1] is null
          appts.pop()

      clear_end()
      for appt, i in appts when appt is null
        appts[i] = appts.pop()
        clear_end()

      if Modal.whichModal() is 'createAppt' and view_filter Appts.pseudo
        unless current_appts_map[Appts.pseudo.id]
          appts.push Appts.pseudo

      unless week_view
        for pro in Pros.data
          pro.levels = 0
        for rsc in Resources.data
          rsc.levels = 0

      for appt in appts
        overlapping = (item for item in appts when overlap_filter appt, item)
        appt.overlapping = overlapping
        overlapping.sort (a, b) ->
          return 1 if a.level > b.level
          -1
        appt.level  = 0
        appt.levels = 0
        for item in overlapping
          appt.level = item.level + 1 if item.level is appt.level

        overlap_check = {}
        (recursive_overlap_check = (appt) ->
          unless overlap_check[appt.id]
            overlap_check[appt.id] = appt
            for item in appt.overlapping or []
              recursive_overlap_check item
          return
        ) appt
        for k, item of overlap_check
          appt.levels = Math.max appt.level, item.level, appt.levels
        for k, item of overlap_check
          item.levels = appt.levels

        if View.view in [CALENDAR__VIEW__HORIZONTAL_DAY,
                         CALENDAR__VIEW__VERTICAL_DAY]
          pro = appt.pro()
          pro.levels = Math.max pro.levels, appt.levels

      group_map =
        cancelled: 'error'
        completed: 'check-alt'
        inOffice:  'inoffice-alt'

      if View.view is CALENDAR__VIEW__HORIZONTAL_DAY
        top = Math.round 2.1 * em_px
        for pro in Pros.withResources()
          pro.top = top
          continue unless pro.visible
          last_pro = pro
          if pro.levels > 1
            em_h   = pro.levels * (View.apptMinHeight + .1) + View.apptHeight
            last_h = Math.round em_h * em_px
          else
            last_h = Math.round View.gradeHeight * em_px
          top += last_h
          pro.height = last_h
          pro.style  = height: last_h + 'px'
          pro.pxBottom = top
        if last_pro
          last_pro.height = Math.round last_h + .5 * em_px
          last_pro.style.height = last_pro.height + 'px'

      for appt in appts
        group = ApptStatus.getGroup appt.data.appointmentStatus
        appt.cancelled   = group is 'cancelled'
        appt.rescheduled = group is 'rescheduled'
        appt.passed      = appt.data.endTime < (new Date).getTime()
        appt.statusClass = group or null

        appt.style = View.apptPos appt

        if View.view is CALENDAR__VIEW__HORIZONTAL_DAY
          {height, top} = appt.style
          appt.pxBottom = top.replace('px', '') - height.replace('px', '') * -1
          delete appt.smallItem
        else
          len = (appt.data.endTime - appt.data.startTime) / 1000
          appt.smallItem = len <= Prefs.increment and View.zoom < 2

        unless group is 'completed'
          appt.style.borderLeftColor = appt.reason()?.color()

      $scope.$parent.$broadcast 'calendar:canvas:appt:update'

    $scope.$on 'calendar:canvas:update', render
    render()
]
