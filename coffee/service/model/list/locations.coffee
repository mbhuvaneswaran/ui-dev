
CalendarCtrl.service 'Locations', [
  'List', 'Location',
  (List, Location) ->

    class Locations extends List
      api:         'Locations'
      recordClass: Location
      sortBy:      'name'

    new Locations
]
