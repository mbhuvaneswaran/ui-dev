
CalendarCanvasCtrl.controller 'ApptPlaceholderCtrl', [
  '$scope', 'Appts', 'Modal', 'Prefs', 'View', 'timez', 'WebTracking'
  ($scope, Appts, Modal, Prefs, View, timez, WebTracking) ->

    last_pro = last_t = x = y = null

    render_range = View.range.render

    render = ->
      filter = ->
        (last_pro is 'pro' + appt.data.providerId or
         (last_pro is 'rsc' + appt.data.resourceId and
          appt.data.providerId is null)) and
        appt.data.startTime / 1000 < render_range[1] and
        appt.data.endTime / 1000 > render_range[0] and
        pseudo.overlap appt

      pseudo = Appts.pseudo
      if $scope.show = (x and y and not Modal.isOpen() and not Appts.hovered and
                        not $scope.sliderGrabbed and View.mouseInSlider) and
                        pseudo

        {pro, sec} = View.posInfo x, y

        if pro and sec and (last_pro isnt pro.xid or sec isnt last_t)
          last_pro = pro.xid
          if pro.data.resourceId?
            pseudo.data.providerId = null
            pseudo.data.resourceId = pro.id
          else
            pseudo.data.providerId = pro.id
            pseudo.data.resourceId = null
          pseudo.startTime last_t = sec
          pseudo.length Prefs.increment

          if View.type is CALENDAR__VIEW__HORIZONTAL
            pseudo.pseudoTop = pro.top
            for appt in Appts.data
              if appt.pxBottom > pseudo.pseudoTop and filter()
                pseudo.pseudoTop = appt.pxBottom
          else
            pseudo.pushed = false
            for appt in Appts.data when filter()
              pseudo.pushed = true
              break

          $scope.style = View.apptPos pseudo, CALENDAR__POS__PSEUDO

          $scope.style.zIndex = 5000

          $scope.info = timez(sec * 1000).format 'h:mma'

    $scope.$on 'calendar:appt', ->
      last_pro = last_t = null
      render()

    $scope.$on 'Pointer::move', (event, _x, _y) ->
      x = _x
      y = _y
      render()

    $scope.$on 'Pointer::click', ->
      if not View.readOnlyProvider and $scope.show and not View.arrowHover and
      render_range[0] <= Appts.pseudo?.startTime().unix() < render_range[1]
        $scope.modalEdit 'create', Appts.pseudo

]
