
CalendarCtrl.service 'ApptReasons', [
  'ApptReason', 'List',
  (ApptReason, List) ->

    class ApptReasons extends List
      api:         'ApptReasons'
      recordClass: ApptReason
      sortBy:      'name'

    new ApptReasons
]
