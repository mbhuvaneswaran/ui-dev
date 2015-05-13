
CalendarCtrl.service 'Prefs', [
  'List', 'Pref',
  (List, Pref) ->

    class Prefs extends List
      api:         'Prefs'
      recordClass: Pref

      constructor: ->
        @if 'load', @loadSpecialValues
        super

      loadSpecialValues: =>
        for item in @data
          switch item.data.name
            when 'calendar.time_zone', 'calender.time_zone'
              @tz = item.data.value
            when 'calendar.minute_increment'
              @incrementMinute = Number item.data.value
              @increment       = item.data.value * 60
        return

    new Prefs
]
