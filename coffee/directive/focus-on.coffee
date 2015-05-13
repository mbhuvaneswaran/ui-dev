
main.directive 'focusOn', [
  '$timeout',
  ($timeout) ->
    restrict: 'A'
    link: (scope, element, attrs) ->
      scope.$watch attrs.focusOn, (new_value, old_value) ->
        return unless new_value and not old_value
        focus()

      focus = ->
        $timeout ->
          try element[0].focus()
        , 1

      focus()
]
