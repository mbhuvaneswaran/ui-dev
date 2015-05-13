
CalendarCanvasCtrl = CalendarCtrl.controller 'CanvasCtrl', [
  '$scope', '$timeout', 'Appts', 'Modal', 'Prefs', 'View', 'timez',
  'WebTracking'
  ($scope, $timeout, Appts, Modal, Prefs, View, timez, WebTracking) ->

    TIME_PICKUP_DISABLE_PERIOD = 200

    slider = $scope.slider = ->
      elem('.calendar .slider')[0]

    focusLineTop = ->
      (slider()?.offsetHeight or 0) * .2 + 2 * View.emPx

    render_range  = View.range.render
    visible_range = View.range.visible

    animate_left = (callback) ->
      animated_scroll slider(), 0, 0, 100, $timeout, callback

    animate_right = (callback) ->
      animated_scroll slider(), View.visibleWidthPx * 2, 0, 100, $timeout,
                      callback
    
    $scope.goToCalendarDate = () ->
      animate_left ->
        dateStr = document.querySelector('#calendar-date')
        if dateStr && dateStr.value
          View.update moment(dateStr.value).unix()
        return
      return
    $scope.goToCalendarMonth = () ->
        dateStr = document.querySelector('#calendar-date')
        if dateStr && dateStr.value
          View.update(moment(this.dateInfo).unix())
        return
      
    $scope.goToPrevDay = ->
      animate_left ->
        View.update View.tz.prevDay().unix()

    $scope.goToCurrentTime = ->
      t = (new Date).getTime() / 1000

      WebTracking.track 'calendar.click.current-time',
        'calendar-type' : View.view

      animated = ->
        View.update t

      if View.type is CALENDAR__VIEW__HORIZONTAL
        span = render_range[1] - render_range[0]
        focus_dif = (span / 3) / 5
        if render_range[0] + focus_dif < t < render_range[1] - focus_dif
          x = (t - render_range[0] - focus_dif) / span * View.visibleWidthPx * 3
          animated_scroll slider(), x, 0, 100, $timeout, animated
        else if t < render_range[0] + focus_dif
          animate_left animated
        else
          animate_right animated
      else
        animated()
        moveToTime timez()

    $scope.goToNextDay = ->
      animate_right ->
        View.update View.tz.nextDay().unix()

    # day view
    $scope.scrollLeft = ->
      pad = View.gradeWidth * View.emPx
      $scope.scrollTo slider().scrollLeft - View.visibleWidthPx + pad
    $scope.scrollRight = ->
      pad = View.gradeWidth * View.emPx
      $scope.scrollTo slider().scrollLeft + View.visibleWidthPx - pad
    $scope.scrollTo = (to_x, callback) ->
      animated_scroll slider(), to_x, 0, 200, $timeout, ->
        px_pos = slider().scrollLeft + View.visibleWidthPx / 5
        View.update render_range[0] + View.pxSec * px_pos
        callback?()

    time_blocks = $scope.timeBlocks ?= []
    unsubscribe = View.if 'update', ->
      empty_array time_blocks
      t = 0
      if (day_len = render_range[1] - render_range[0]) > ONE_DAY_SECONDS + 3600
        day_len = ONE_DAY_SECONDS # 2+ days, we show 24 hrs days, i.e. week view
      while t < day_len
        time_blocks.push
          hm: timez((render_range[0] + t) * 1000).format 'h:mma'
        t += Prefs.increment

      $scope.render()

    $scope.modalEdit = (mode, appt) ->
      Modal.record = appt
      Modal.open mode + 'Appt'

    $scope.render = render = ->
      return if not $scope.calendarReady or View.view is CALENDAR__VIEW__MONTH

      if View.type is CALENDAR__VIEW__VERTICAL
        if columns_node = elem('.calendar .slider .columns')[0]
          $scope.columnsWidth = (columns_node.offsetWidth - 1) + 'px'

      if View.view is CALENDAR__VIEW__WEEK
        today = Number timez().format 'YYYYMMDD'
        unless View.days[0]?.tz?.unix() is visible_range[0]
          for day, i in View.days
            if i
              day.tz = View.days[i - 1].tz.nextDay()
            else
              day.tz = visible_range.tz[0]
            day.today  = (n = Number day.tz.format 'YYYYMMDD') is today
            day.future = n > today

        $scope.dateInfo = visible_range.tz[0].format('MMM D') + ' - ' +
                          visible_range.tz[1].prevDay().format('MMM D')
      else # CALENDAR__VIEW__HORIZONTAL_DAY, CALENDAR__VIEW__VERTICAL_DAY
        $scope.prevDay = View.tz.prevDay().format 'ddd'
        $scope.nextDay = View.tz.nextDay().format 'ddd'

        $scope.dateInfo = View.tz.format 'dddd, MMMM D, YYYY'

      if View.tz?
        if moment().format('Z') isnt View.tz.format 'Z'
          $scope.dateInfo += ' ' + View.tz.format 'z'
        if View.tz.format('YYMMD') is timez().format 'YYMMD'
          $scope.dateInfo += ' (today)'

      moveToTime()
      $scope.$broadcast 'calendar:canvas:update'

    (moveToTime = (tz=View.tz) ->
      close = (current, target) ->
        allowance = Math.ceil 60 / View.pxSec * 2 # 2 minutes on canvas
        current - allowance < target < current + allowance

      unless slider() and View.tz
        return unsubscribe.add $timeout moveToTime, 50

      if View.type is CALENDAR__VIEW__HORIZONTAL
        unless close slider().scrollLeft, View.visibleWidthPx
          slider().scrollLeft = View.visibleWidthPx
          unless slider().scrollLeft
            unsubscribe.add $timeout moveToTime, 50
      else
        top = Math.floor View.tz.secOfDay() / View.pxSec - focusLineTop()
        unless close slider().scrollTop, top
          slider().scrollTop = top
    )()

    pointer_operation_check = ->
      View.type is CALENDAR__VIEW__HORIZONTAL and not Modal.isOpen() and
      View.mouseInSlider and not Appts.hovered

    $scope.$on 'Pointer::drag', (event, delta_x, delta_y, x, y) ->
      if pointer_operation_check()
        $scope.sliderGrabbed = true
        slider().scrollLeft = View.visibleWidthPx - delta_x

    $scope.$on 'Pointer::dragEnd', (event, delta_x, delta_y) ->
      if pointer_operation_check()
        return unless $scope.sliderGrabbed
        $scope.sliderGrabbed = false
        View.update View.time - delta_x * View.pxSec

    last_scroll_state_y = null
    $scope.$on 'scroll:calendar-slider', (event, x, y) ->
      last_scroll_state_y = y
      unsubscribe.add $timeout ->
        if y is last_scroll_state_y and not $scope.sliderGrabbed
          View.update Math.floor render_range[0] +
                                 (y + focusLineTop()) * View.pxSec
      , TIME_PICKUP_DISABLE_PERIOD

    t_in_range = (item) ->
      visible_range[0] <= item.startTime / 1000 < visible_range[1] or
      visible_range[0] <= item.endTime / 1000 < visible_range[1] or
      visible_range[0] <= item.startDateTime / 1000 < visible_range[1] or
      visible_range[0] <= item.endDateTime / 1000 < visible_range[1]

    $scope.$on 'calendar:appt', (event, data) ->
      if (list = data?.results)?.length # check if data is updated in the range
        for item in list when t_in_range item
          return render()
      else
        render()
    render()

    $scope.$on '$destroy', unsubscribe
]
