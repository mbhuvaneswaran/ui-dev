
CalendarCanvasCtrl.controller 'TimeOffCtrl', [
  '$scope', 'Pros', 'TimeOffs', 'View',
  ($scope, Pros, TimeOffs, View) ->

    render_range = View.range.render

    time_off = $scope.time_off = []

    render = ->
      return unless $scope.calendarReady

      empty_array time_off

      filter = (appt) ->
        pro_filter = (slice) ->
          pro = slice.pro()
          if View.view is CALENDAR__VIEW__WEEK
            return Pros.selectedProviderId is pro?.xid
          pro?.visible

        slices = []
        for slice in View.daySlice appt
          data  = slice.data
          end   = data.endDateTime / 1000
          start = data.startDateTime / 1000

          if pro_filter(slice) and
          ((end > render_range[0] and start < render_range[1]) or
          (end >= render_range[1] and start <= render_range[0]))
            slices.push slice

            if start < render_range[0]
              slice.saved.startDateTime = render_range[0] * 1000
            if end > render_range[1]
              slice.saved.endDateTime = render_range[1] * 1000

        slices

      for appt in TimeOffs.data when (slices = filter appt).length
        for slice in slices
          slice.style = View.apptPos slice, CALENDAR__POS__FULL_COVER

          t_distance = 4 * 60 * 60 # 4 hrs
          labels = slice.labels ?= []
          len = slice.data.endDateTime - slice.data.startDateTime
          n_labels = Math.ceil len / t_distance / 1000 # 4 hr
          for i in [0 ... n_labels]
            push = (i * t_distance / View.pxSec) + 'px'
            label = labels[i] ?= {}
            if View.type is CALENDAR__VIEW__VERTICAL
              label.style = top: push
            else
              label.style = {left: push, bottom: 0}
          while labels.length > n_labels
            labels.pop()

          time_off.push slice

    $scope.$on 'calendar:canvas:appt:update', render

    render()
]
