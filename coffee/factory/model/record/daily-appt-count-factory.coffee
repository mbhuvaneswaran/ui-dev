
main.factory 'DailyApptCountFactory', [
  'Record',
  (Record) ->

    class DailyApptCount extends Record
      api:        'DailyApptCount'
      idProperty: ['localDate', 'providerId', 'serviceLocationId', 'resourceId']
]
