
CalendarCtrl.directive 'resizable', [
  '$window', 'View',
  ($window, View) ->

    last_w = last_h = null

    ($scope) ->
      angular.element($window).bind 'resize', ->
        h = $window.innerHeight
        w = $window.innerWidth

        unless last_h is h and last_w is w
          last_h = h
          last_w = w
          View.rangeUpdate()
]
