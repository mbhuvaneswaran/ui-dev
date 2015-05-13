
main.service 'TimeOffsFactory', [
  'ApptsFactory', 'TimeOff', 'timez',
  (ApptsFactory, TimeOff, timez) ->

    MAX_DAYS_PER_PAGE = 367

    class TimeOffsFactory extends ApptsFactory
      api: 'TimeOff'
      recordClass: TimeOff
      listProperty: 'results'
      sortBy:
        property: 'startDateTime'
        type: 'number'

      loadYearAhead: (callback) ->
        now = timez()
        minTime = now.startOf('day').valueOf()
        maxTime = now.endOf('day').add('years', 1).valueOf()

        @load
          minDateTime: minTime
          maxDateTime: maxTime
          maxDaysPerPage: MAX_DAYS_PER_PAGE
        , callback
]
