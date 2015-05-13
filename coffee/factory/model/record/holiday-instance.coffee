
main.factory 'HolidayInstance', [
  'Record',
  (Record) ->
    class HolidayInstance extends Record
      api: 'HolidayInstance'
      idProperty: 'holidayInstanceId'

      INPUT_FORMAT = 'DD-MMM-YY'
      OUTPUT_FORMAT = 'dddd, MMMM D, YYYY'

      formattedDate: =>
        moment(@data.holidayInstanceDate, INPUT_FORMAT).format(OUTPUT_FORMAT)

      dateValue: =>
        moment(@data.holidayInstanceDate, INPUT_FORMAT).valueOf()

]
