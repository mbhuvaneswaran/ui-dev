# automatically applies dropup toggle to any div element with class 'dropup'
main.directive "dropup", ['$timeout', '$document', ($timeout, $document) ->
  restrict: "C"

  link: (scope, element, attr) ->
    activeClass = 'active'
    elementClicked = false
    bodyCheckDelay = 10
    clickResetDelay = 20

    element.bind('click', ->
      elementClicked = true

      if element.hasClass(activeClass)
        element.removeClass(activeClass)
      else
        element.addClass(activeClass)
    )

    body = $document.find('body')
    body.bind('click', ->
      $timeout(->
        if !elementClicked
          element.removeClass(activeClass)
        resetClick()
      , bodyCheckDelay)
    )

    resetClick = () ->
      $timeout(->
        elementClicked = false
      , clickResetDelay)
]