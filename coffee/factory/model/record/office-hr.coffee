
main.factory 'OfficeHr', [
  'Appt', 'Record', 'timez'
  (Appt, Record, timez) ->

    abs_time_cache = {}

    class OfficeHr extends Record
      api:        'OfficeHr'
      idProperty: 'officeHrsId'

      absTime: (millisecond_of_day, day_ref) ->
        ref = day_ref.format('YYYYMMDD') + String millisecond_of_day
        unless abs_time_cache[ref]?
          s = Math.floor millisecond_of_day / 1000
          h = Math.floor s / 3600
          s -= h * 3600
          m = Math.floor s / 60
          s -= m * 60
          tz = timez(day_ref).startOfDay().hour(h).minute(m).second(s)
          abs_time_cache[ref] = tz.unix()
        abs_time_cache[ref]

      absEndSec: (day_ref) =>
        @absTime @data.endTime, day_ref

      absStartSec: (day_ref) =>
        @absTime @data.startTime, day_ref

      pro: Appt::pro
]
