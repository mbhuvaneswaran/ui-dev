
main.service 'DailyApptCounts', [
  'DailyApptCountsFactory', 'View',
  (DailyApptCountsFactory, View) ->

    list = new DailyApptCountsFactory

    View.ifSync 'update', ->
      if View.view and View.view is CALENDAR__VIEW__MONTH
        list.loadRange View.range.visible...

    list
]
