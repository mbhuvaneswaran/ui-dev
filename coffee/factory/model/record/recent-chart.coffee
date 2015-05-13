
main.factory 'RecentChart', [
  'Record',
  (Record) ->

    class RecentChart extends Record
      api:        'RecentChart'
      idProperty: 'patientId'
]
