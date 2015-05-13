
CalendarCanvasCtrl.controller 'OfficeHoursCtrl', [
  '$scope', 'OfficeHrs', 'Pros', 'View',
  ($scope, OfficeHrs, Pros, View) ->

    outputs = {}
    outputs[CALENDAR__OFFICE_HRS__BREAK_TYPE]     = $scope.breaks     = []
    outputs[CALENDAR__OFFICE_HRS__OFFICE_HR_TYPE] = $scope.office_hrs = []

    render_range = View.range.render

    render = ->
      return unless $scope.calendarReady and OfficeHrs.hasLoaded

      for k, v of outputs
        empty_array v

      days = []
      day = render_range.tz[0].startOfDay()
      while day.unix() < render_range[1]
        days.push day
        day = day.nextDay()

      filter = (item) ->
        pro_filter = ->
          pro = item.pro()
          if View.view is CALENDAR__VIEW__WEEK
            return Pros.selectedProviderId is pro?.xid
          pro?.visible

        data = item.data

        pro_filter() and
        data.dayOfWeek is d_of_w and
        outputs[data.officeHrsCategory]?

      for day in days
        d_of_w = day.day()
        for item in OfficeHrs.data when filter item
          type  = item.data.officeHrsCategory
          end   = item.absEndSec day
          start = item.absStartSec day

          if (end > render_range[0] and start < render_range[1]) or
          (end >= render_range[1] and start <= render_range[0])
            item._end   = end
            item._start = start

            data =
              dayOfWeek:  item.data.dayOfWeek
              endTime:    end * 1000
              providerId: item.data.providerId
              resourceId: item.data.resourceId
              startTime:  start * 1000

            item.style = View.apptPos {data}, CALENDAR__POS__FULL_COVER
            outputs[type].push item

    $scope.$on 'calendar:canvas:appt:update', render
    render()
]
