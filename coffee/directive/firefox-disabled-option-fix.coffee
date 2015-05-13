
CalendarCtrl.directive 'firefoxDisabledOptionFix', [
  '$timeout',
  ($timeout)->
    restrict: "A"

    exec = (node)->
      $timeout(->
        node.selectedIndex = 0
      , 300)

    link: (scope, element, attrs) ->
      node = element[0]

      a = attrs.firefoxDisabledOptionIgnore

      unless a in ['true', true]
        exec(node)

]
