
CalendarCtrl.directive 'scroll', [
  '$rootScope',
  ($rootScope) ->
    last_x = 0
    last_y = 0

    restrict: "A"

    scope:
      scroll: '@'

    link: (scope, element) ->

      node = element[0]

      name = scope.scroll or 'scroll'
      name = 'scroll:' + scope.scroll unless name is 'scroll'

      element.bind 'scroll', ->
        x = node.scrollLeft
        y = node.scrollTop
        delta_x = last_x - x
        delta_y = last_y - y
        last_x = x
        last_y = y
        $rootScope.$broadcast name, x, y, delta_x, delta_y
]
