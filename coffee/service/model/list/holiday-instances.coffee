
main.service 'HolidayInstancesChild', [
  'CustomHolidaysMaster', 'HolidayInstance', 'List', 'Prefs',
  'RangeCacheFactory', 'View', 'timez',
  (CustomHolidaysMaster, HolidayInstance, List, Prefs,
   RangeCacheFactory, View, timez) ->

    ##
    # This is a CHILD object for CustomHolidaysMaster
    ##
    class HolidayInstancesChild extends List
      api: 'HolidayInstance'
      recordClass: HolidayInstance
      sortBy: 'holidayName'

      INPUT_FORMAT = 'DD-MMM-YY'

      constructor: ->
        super
        @rangeCache = new RangeCacheFactory

      clear: ->
        @clearCache()
        super

      clearCache: ->
        @rangeCache.clear()

      loadRange: (min, max) =>
        Prefs.if1Sync 'load', =>
          # min -> floor (to 0 hour)
          min = timez(min * 1000).hour(0).minute(0).second(0).unix()
          # max -> round up (to next day 0 hour, if not on 0 hour)
          if (tz = timez max * 1000).hour() or tz.minute() or tz.second()
            tz.day(tz.day() + 1).hour(0).minute(0).second(0)
          max = tz.unix()

          for loadable in @rangeCache.uncovered min, max
            [min, max] = loadable
            @load
              deleted:   false
              startDate: timez(min * 1000).format INPUT_FORMAT
              endDate:   timez(max * 1000).format INPUT_FORMAT

      upsert: (info) =>
        if info.holidayInstanceId?
          super
        else
          @masterUpsert(info)

      masterUpsert: (info) ->
        CustomHolidaysMaster.upsert(info)


    # service
    holidays = new HolidayInstancesChild

    View.ifSync 'update', ->
      if View.view and View.view is CALENDAR__VIEW__MONTH
        holidays.loadRange View.range.visible...

    Prefs.if1Sync 'load', ->
      startDate = (start = timez()).unix()
      endDate   = start.nextYear().prevDay().unix()
      holidays.loadRange startDate, endDate

    holidays
]
