
CalendarCtrl.factory 'ApptReason', [
  'Record',
  (Record) ->

    class ApptReason extends Record
      api:        'ApptReason'
      idProperty: 'appointmentReasonId'

      color: ->
        HexRGBConverter::numToHex @data.rgbColor
]
