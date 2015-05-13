
CalendarCanvasCtrl.controller 'GradesCtrl', [
  '$scope', 'Prefs', 'View', 'timez',
  ($scope, Prefs, View, timez) ->

    $scope.grades   = grades = []
    $scope.timeCaps = caps   = []

    render_range = View.range.render

    render = ->
      grade_width_px = View.gradeWidth * View.emPx

      i = 0
      increment = Prefs.increment
      pos = (0 - render_range[0] % increment) / increment * grade_width_px
      while pos < View.sliderWidthPx + grade_width_px
        unless grades.length > i
          grades.push({})
          caps.push(style: {})
        grade = grades[i]
        grade.top  = '1.7em'
        grade.left = pos + 'px'
        sec = Math.round render_range[0] + View.pxSec * pos + 10
        grade.width = (grade_width_px - 1) + 'px'

        cap = caps[i]
        cap.t = timez(sec * 1000).format 'h:mma'
        cap.style.left = (pos - 2 * View.emPx) + 'px'
        cap.style.display = 'block'

        i   += 1
        pos += grade_width_px

      while grades.length > i
        grades.pop()
        caps.pop()

      if grade_width_px < 4 * View.emPx
        mod = 2
        if grade_width_px < 2 * View.emPx
          mod = 4
        if grade_width_px < 1 * View.emPx
          mod = 8

        modval = 0
        for cap, i in caps
          if cap.t.indexOf(':00') > -1
            modval = i % mod
            break
        for cap, i in caps
          if i % mod isnt modval
            cap.style.display = 'none'
            grades[i].top = '2em'

    $scope.$on 'calendar:appt', render
    render()
]
