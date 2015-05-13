
CalendarCanvasCtrl.controller 'CurrentTimeCtrl', [
  '$interval', '$scope', 'View', 'timez',
  ($interval, $scope, View, timez) ->

    render_range = View.range.render

    px_to_num = (px) ->
      Number String(px).replace 'px', ''

    render = ->
      return unless $scope.calendarReady

      now = Math.floor (new Date).getTime() / 1000

      if $scope.show = (render_range[0] <= now < render_range[1])
        tz = timez now * 1000

        $scope.time = tz.format 'h:mma'

        data =
          dayOfWeek: tz.day()
          startTime: now * 1000

        $scope.lineStyle = style = View.apptPos {data}, CALENDAR__POS__TIMELINE

        if $scope.showCap = (View.type is CALENDAR__VIEW__HORIZONTAL)
          pos = px_to_num style.left
          $scope.capStyle = left: (pos - 1.5 * View.emPx) + 'px'
        else
          if View.view is CALENDAR__VIEW__VERTICAL_DAY
            style.left  = 0
            style.width = '100%'

          $scope.arrowStyle = top: (px_to_num(style.top) - 6) + 'px'

    $scope.$on 'calendar:canvas:appt:update', render

    interval_ref = $interval render, 100

    $scope.$on '$destroy', ->
      $interval.cancel interval_ref
]
