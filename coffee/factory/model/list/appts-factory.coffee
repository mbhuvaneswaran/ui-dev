
main.factory 'ApptsFactory', [
  '$http', '$timeout', 'Appt', 'List',
  ($http, $timeout, Appt, List) ->

    class ApptsFactory extends List
      api:          'Appts'
      listProperty: 'results'
      recordClass:  Appt
      sortBy:       'startTime'

      constructor: ->
        super
        @loadedDays = {}

      clear: ->
        @clearCache()
        super

      clearCache: (min, max) ->
        if min and max
          for start of @loadedDays
            if min - ONE_DAY_SECONDS < start < max + ONE_DAY_SECONDS
              delete @loadedDays[start]
        else
          empty_object @loadedDays

      loadRange: (min, max, max_day_block_size) =>
        return unless min > 1 and max > 1

        for block in @rangeToLoadables min, max, null, max_day_block_size
          for i in [0 ... block.days] # mark days as loaded/cached
            @loadedDays[block.start + i * ONE_DAY_SECONDS] = true

          end_time = block.start + block.days * ONE_DAY_SECONDS

          suffix = if @api is 'TimeOff' then 'Time' else ''

          inf = {deleted: false, maxDaysPerPage: block.days}
          inf['minDate' + suffix] = block.start * 1000
          inf['maxDate' + suffix] = end_time * 1000

          @load inf
        return

      rangeToLoadables: (min, max, middle, max_days=8) ->
        ###
        Will generate loadables in the format of
        [{start: unix_time_seconds, days: n_days}, {start: U, days: N}, ...]
        Sorted based on distance from the middle of the range
        ###
        middle ?= (max - min) / 2 + min

        t = min - (min % ONE_DAY_SECONDS) # previous utc day start
        list = []
        last = null
        while t < max
          unless @loadedDays[t]
            target = list[list.length - 1]
            if last is t - ONE_DAY_SECONDS and target.days < (max_days or 1024)
              target.days += 1
            else
              list.push {days: 1, start: t}
            last = t
          t += ONE_DAY_SECONDS

        list.sort (a, b) ->
          a = Math.abs middle - (a.days * ONE_DAY_SECONDS / 2 + a.start)
          b = Math.abs middle - (b.days * ONE_DAY_SECONDS / 2 + b.start)
          return 1 if a > b
          -1

        list

      setPseudo: =>
        @pseudo = new Appt appointmentId: 'pseudo'
]
