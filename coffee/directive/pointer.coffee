CalendarCtrl.directive 'pointer', [
  '$rootScope', '$window',
  ($rootScope, $window) ->

    event_coords = (event) ->
      x: event.pageX or event.clientX + document.body.scrollLeft
      y: event.pageY or event.clientY + document.body.scrollTop

    info = $rootScope.Pointer =
      downPos:  null
      dragging: false
      pos:
        x: -1
        y: -1

    angular.element($window).bind 'mousedown', (event) ->
      if event.which is 1 # left mouse button only
        {x, y} = event_coords event
        info.downPos = {x, y}
        $rootScope.$broadcast 'Pointer::down', x, y

    angular.element($window).bind 'mousemove', (event) ->
      {x, y} = event_coords event
      info.pos.x = x
      info.pos.y = y
      $rootScope.$broadcast 'Pointer::move', x, y

      if info.downPos
        info.dragging = true
        x_delta = x - info.downPos.x
        y_delta = y - info.downPos.y
        $rootScope.$broadcast 'Pointer::drag', x_delta, y_delta, x, y

    angular.element($window).bind 'mouseup', (event) ->
      if event.which is 1 # left mouse button only
        {x, y} = event_coords event
        $rootScope.$broadcast 'Pointer::up', x, y

        down_pos = info.downPos
        if info.dragging and down_pos
          x_delta = x - down_pos.x
          y_delta = y - down_pos.y
          $rootScope.$broadcast 'Pointer::dragEnd', x_delta, y_delta, x, y
        else if down_pos and x is down_pos.x and y is down_pos.y
          $rootScope.$broadcast 'Pointer::click', x, y
        info.downPos  = null
        info.dragging = false

    -> # returning empty function. Nothing scope-related happens here
]
