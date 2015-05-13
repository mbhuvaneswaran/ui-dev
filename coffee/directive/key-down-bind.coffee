
CalendarCtrl.directive 'keyDownBind', [
  '$parse',
  ($parse)->
    restrict: "A"

    link: (scope, element, attrs) ->
      node = element[0]
      angular.element(node).bind 'keydown', (event) ->
        args =
          event: event
        invoker = $parse(attrs.keyDownBindFunction)
        invoker(scope, args)

]
