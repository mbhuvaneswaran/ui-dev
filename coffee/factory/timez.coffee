
CalendarCtrl.factory 'timez', [
  'Prefs',
  (Prefs) ->

    split = (tz) ->
      (Number(n) for n in tz.format('YYYY-MM-DD-HH-mm-ss').split '-')

    fn = (args...) ->
      fn._tz ?= Prefs.tz
      return unless tz = moment.tz args..., fn._tz

      if isNaN tz.valueOf()
        throw new Error 'Invalid timez: ' + args.join ', '

      tz.nextDay = (count=1) ->
        # NOTE: moment.tz('2014-11-02 00:00:00').add(1, 'd') is buggy, will
        #       return 2014-11-02 01:00:00 in current version
        #       Original code (using standard momentjs interface)
        # fn(tz).add count, 'd'
        #       Replacement:
        unless count # count == 0, just create a copy
          return fn tz
        [y, m, d, h, i, s] = split tz
        obj = fn()
          .year(y)
          .month(m - 1)
          .date(d + Number count)
          .hour(h)
          .minute(i)
          .second(s)
        # workaround for sliding hours on daylight switch days
        utc_offset = (t) ->
          str = t.format()
          str = str.substr str.length - 6
          min = Number(str[5]) + Number(str[4]) * 10 +
                (Number(str[2]) + Number(str[1]) * 10) * 60
          if str[0] is '-'
            return min * -60
          min * 60

        off_check = ->
          off_by = (obj.unix() - obj.zone() * 60 - tz.unix() + tz.zone() * 60) -
                   86400 * count
          if off_by
            obj.subtract off_by, 's'
          off_by

        if off_check()
          # dbl-check is needed, the first try might have had bugous utc offset
          off_check()

        obj

      tz.nextMonth = (count=1) ->
        [y, m, d, h, i, s] = split tz
        fn()
          .year(y)
          .month(m - 1 + Number count)
          .date(d)
          .hour(h)
          .minute(i)
          .second(s)
      tz.nextYear = (count=1) ->
        fn(tz).add count, 'y'

      tz.prevDay = (count=1) ->
        # see note at tz.nextDay
        # fn(tz).subtract count, 'd'
        tz.nextDay count * -1
      tz.prevMonth = (count=1) ->
        [y, m, d, h, i, s] = split tz
        fn()
          .year(y)
          .month(m - 1 - Number count)
          .date(d)
          .hour(h)
          .minute(i)
          .second(s)
      tz.prevYear = (count=1) ->
        fn(tz).subtract count, 'y'

      tz.startOfDay = () ->
        # NOTE bug in moment-timezone 0.0.1
        # fn tz.format 'YYYY-MM-DD'

        [y, m, d] = (Number(n) for n in tz.format('YYYY-MM-DD').split '-')
        obj = fn()
          .year(y)
          .month(m - 1)
          .date(d)
          .hour(0)
          .minute(0)
          .second(0)
          .startOf 'day'
        # at times it will be a day off, workaround:
        if (diff = tz.unix() - obj.unix()) > 90000
          obj.add diff - (diff % 86400), 's'
        if h = obj.hour()
          obj.add 24 - h, 'h'
        if obj.day() - tz.day() in [-1, 6]
          obj.add 1, 'd'
        obj

      tz.startOfWeek = (monday_start=true) ->
        d = tz.day() # sunday based
        if monday_start
          d = (d + 6) % 7
        if d
          tz.startOfDay().prevDay d
        else
          tz.startOfDay()

      tz.startOfMonth = ->
        [y, m] = tz.format('YYYY-MM').split '-'
        fn()
          .year(Number y)
          .month(Number(m) - 1)
          .date(1)
          .hour(0)
          .minute(0)
          .second(0)

      tz.startOfYear = ->
        fn()
          .year(tz.year())
          .month(0)
          .date(1)
          .hour(0)
          .minute(0)
          .second(0)

      tz.secOfUtcDay = ->
        tz.unix() - moment(tz.valueOf()).utc().startOf('day').unix()
      tz.secOfDay = ->
        tz.unix() - tz.startOfDay().unix()
      tz.secOfMonth = ->
        tz.unix() - tz.startOfMonth().unix()
      tz.secOfYear = ->
        tz.unix() - tz.startOfYear().unix()

      tz.dateWithCurrentTime = ->
        fn tz.format('YYYY-MM-DD ') + fn().format('hh:ii:ss') * 1

      tz

    fn.zoneSafe = (args...) ->
      local = moment args...
      fn()
        .year(local.year())
        .month(local.month())
        .date(local.date())
        .hour(local.hour())
        .minute(local.minute())
        .second(local.second())

    fn._tz = null

    fn
]
