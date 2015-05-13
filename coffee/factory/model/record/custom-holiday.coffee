
main.factory 'CustomHoliday', [
  'Record',
  (Record) ->
    class CustomHoliday extends Record
      api: 'CustomHoliday'
      idProperty: 'customHolidayId'

      INPUT_FORMAT = 'DD-MMM-YY'
      OUTPUT_FORMAT = 'dddd, MMMM D, YYYY'

      formattedDate: =>
        moment(@data.holidayInstanceDate, INPUT_FORMAT).format(OUTPUT_FORMAT)

      dateValue: =>
        moment(@data.holidayInstanceDate, INPUT_FORMAT).valueOf()

]
