main.directive "sticky", ['$window', ($window) ->
  restrict: "A"
  scope:
    stickyOffset: '@'

  link: (scope, element, attr) ->
    offset = scope.stickyOffset or 0
    wrapperNode = elem('.body-wrap-inner')[0]

    scrollHandler = ->
      element.css "margin-top":
        Math.max(0, wrapperNode.scrollTop - offset) + "px"

    elem('.body-wrap-inner').bind "scroll", scrollHandler
    element.on "$destroy", ->
      elem('.body-wrap-inner').unbind "scroll", scrollHandler
]