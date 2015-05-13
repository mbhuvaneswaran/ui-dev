
main.factory 'DailyApptCountsFactory', [
  'ApptsFactory', 'DailyApptCountFactory', 'RangeCacheFactory',
  (ApptsFactory, DailyApptCountFactory, RangeCacheFactory) ->

    class DailyApptCounts extends ApptsFactory
      api:          'DailyApptCount'
      listProperty: 'appointmentCounts'
      recordClass:  DailyApptCountFactory

      constructor: ->
        super
        @rangeCache = new RangeCacheFactory

      clear: ->
        @clearCache()
        super

      clearCache: ->
        @rangeCache.clear()

      loadRange: (min, max) ->
        for loadable in @rangeCache.uncovered min, max
          [min, max] = loadable
          while max - min > 0
            to = Math.min min + 43 * ONE_DAY_SECONDS, max
            @load
              deleted:        false
              minDate:        min * 1000
              maxDate:        to * 1000
              maxDaysPerPage: Math.ceil (to - min) / ONE_DAY_SECONDS + 1 / 24
            min += 43 * ONE_DAY_SECONDS
]
