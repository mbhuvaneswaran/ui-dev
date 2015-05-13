
main.factory 'SynchronizedAppt', [
  'Record',
  (Record) ->

    class SynchronizedAppt extends Record
      api:        'SynchronizedAppt'
      idProperty: 'appointmentId'
]