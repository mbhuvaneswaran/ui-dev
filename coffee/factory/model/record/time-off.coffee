
main.factory 'TimeOff', [
  'Appt', 'Record', 'timez',
  (Appt, Record, timez) ->

    class TimeOff extends Record
      api:        'TimeOff'
      idProperty: 'timeOffId'

      _tz: Appt::_tz

      endTime: =>
        @_tz 'endDateTime'

      pro: Appt::pro

      startTime: =>
        @_tz 'startDateTime'
]
