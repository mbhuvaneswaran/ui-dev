
CalendarCtrl.controller 'MonthViewCtrl', [
  '$scope', 'CustomHolidaysMaster', 'DailyApptCounts', 'HolidayInstancesChild',
  'Locations', 'Pros', 'Resources', 'View', 'timez', 'WebTracking'
  ($scope, CustomHolidaysMaster, DailyApptCounts, HolidayInstancesChild,
   Locations, Pros, Resources, View, timez, WebTracking) ->

    $scope.goToCurrent = ->
      View.update (new Date).getTime() / 1000
      WebTracking.track 'calendar.click.current-time',
        'calendar-type':View.view

    visible_range = View.range.visible

    $scope.DailyApptCounts = DailyApptCounts

    $scope.days = days = ({} for i in [0 ... 6 * 7])

    $scope.dayColumns = cols = for i in [0 .. 6]
      days: (day for day, ii in days when ii % 7 is i)
      name: moment().day(i).format 'dddd'

    get_holidays_for_day = (tz) ->
      list = []
      for holiday in CustomHolidaysMaster.data.concat HolidayInstancesChild.data
        if holiday.data.holidayInstanceDate is tz.format 'DD-MMM-YY'
          list.push holiday.data.holidayName
      return unless list.length
      list.join ', '

    $scope.render = render = ->
      return unless $scope.calendarReady and View.view is CALENDAR__VIEW__MONTH

      $scope.dateInfo  = View.tz.format 'MMMM YYYY'
      $scope.prevMonth = View.tz.prevMonth().format 'MMM'
      $scope.nextMonth = View.tz.nextMonth().format 'MMM'

      pos = visible_range.tz[0]

      $scope.today = today = timez()
      today_date = Number today.format 'YYMMDD'
      YM = 'YYYYMM'
      id = 0
      focused_mo = Number View.tz.format YM
      $scope.currentMonth = focused_mo is Number today.format YM
      identical_days = days[0].time is pos.unix()
      for day in days
        delete day.appts

        unless day.holidays = get_holidays_for_day pos
          delete day.holidays

        unless identical_days
          mo = Number pos.format YM
          first_day = pos.day() is 0
          hidden = true if mo > focused_mo and first_day

          day.show    = not hidden
          day.date    = pos.format 'D'
          day.time    = pos
          day.first   = first_day

          day.prevMonth = mo < focused_mo
          day.past      = pos_date < today_date
          day.today     = (pos_date = Number pos.format 'YYMMDD') is today_date
          day.future    = pos_date > today_date
          day.nextMonth = mo > focused_mo

          day.goToDay = ->
            if @today
              t = (new Date).getTime() / 1000
            else
              t = @time.hour(9).unix()
            View.update CALENDAR__VIEW__HORIZONTAL_DAY, t

          day.startTime = pos.unix()
          pos = pos.nextDay()
          day.endTime = pos.unix()

      get_day = (count) ->
        if t_in_range(t = count.data.localDate / 1000) and
        Locations.get(count.data.serviceLocationId)?.visible and
        (Pros.get(count.data.providerId)?.visible or
         Resources.get(count.data.resourceId)?.visible)
          for day in days when day.startTime <= t < day.endTime
            return day
        false

      for count in DailyApptCounts.data when (day = get_day count) isnt false
        day.appts = (day.appts or 0) + count.data.count

      total_count = 0
      start_of_month = (start_month = View.tz.startOfMonth()).unix()
      end_of_month = start_month.nextMonth().unix()
      for day in days
        if start_of_month <= day.time.unix() < end_of_month
          total_count += day.appts or 0

      unless DailyApptCounts.pendingHttp
        WebTracking.track 'calendar.event.month-loaded',
          month: View.tz?.format 'M'
          year: View.tz?.format 'YYYY'
          'total-appointments': total_count
          'num-providers': Pros.countVisible 1

    t_in_range = (t) ->
      visible_range[0] <= t < visible_range[1]

    $scope.$on 'calendar:appt', (event, data) ->
      # check if data is updated in the range
      if (list = data?.appointmentCounts)?.length
        for item in list when item.count t_in_range item.localDate / 1000
          return render()
      else
        render()

    render()
]
