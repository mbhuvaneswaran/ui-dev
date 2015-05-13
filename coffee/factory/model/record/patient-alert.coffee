
main.factory 'PatientAlert', [
  'Record',
  (Record) ->

    class PatientAlert extends Record
      api:        'PatientAlert'
      idProperty: 'PatientAlertId'

      messageParts: () ->
        parts = @data.alertMessage.split('\r\n')
        parts_obj = []
        for part in parts
          parts_obj.push({ message: part }) if part.length > 0

        parts_obj
]