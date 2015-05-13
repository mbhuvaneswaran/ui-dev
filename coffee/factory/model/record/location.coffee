
CalendarCtrl.factory 'Location', [
  'Record',
  (Record) ->

    class Location extends Record
      api:        'Location'
      cookieHide: 'hiddenLocations'
      idProperty: 'serviceLocationId'
]
