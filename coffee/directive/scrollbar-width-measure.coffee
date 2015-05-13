
main.directive 'scrollbarWidthMeasure', [
  '$rootScope',
  ($rootScope) ->

    restrict: 'E'

    link: fn = (scope, element, attr) ->
      $rootScope.scrollbarWidth = element[0]?.offsetWidth
]
