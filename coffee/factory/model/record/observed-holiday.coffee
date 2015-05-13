
main.factory 'ObservedHoliday', [
  'Record',
  (Record) ->
    class ObservedHoliday extends Record
      api: 'ObservedHoliday'
      idProperty: 'holidayId'

      entity: =>
        {holidayId: Number(@data.holidayId),
        holidayName: @data.holidayName,
        observed: @data.observed}

]
