
main.service 'ObservedHolidays', [
  'List', 'ObservedHoliday',
  (List, ObservedHoliday) ->

    class ObservedHolidays extends List
      api: 'ObservedHoliday'
      recordClass: ObservedHoliday
      sortBy: 'holidayId'
      collectionSupport: {save: 'post', delete: true}

      constructor: ->
        super
        @load()

    new ObservedHolidays

]
