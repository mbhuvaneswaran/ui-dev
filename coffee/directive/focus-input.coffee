# Applies a focus event on a target element when the given element is clicked
main.directive "focusInput", ['$timeout', ($timeout) ->
  restrict: "A"
  scope:
    focusInputTarget: '@',
    focusInputDelay: '@'

  link: (scope, element, attr) ->
    element.bind('click', ->
      $timeout(->
        elem(scope.focusInputTarget)[0].focus()
      ,scope.focusInputDelay || 0)
    )
]