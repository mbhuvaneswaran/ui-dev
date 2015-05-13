
main.factory 'RecurrenceException', [
  '$http', 'Record', 'UrlFor',
  ($http, Record, UrlFor) ->

    class RecurrenceException extends Record
      idProperty: 'appointmentId'

      save: (appointmentId, occurrenceId, callback) =>
        url = UrlFor.api('Appt') + appointmentId + '/exception/' + occurrenceId

        @saving = true

        req = $http['post'] url

        req.success (data) =>
          @saving = false
          @replace data
          callback?()

        req.error (data, status, headers, config) =>
          @saving = false
          console.error? 'error', arguments
          alert 'Failed to save'
          callback? arguments
]
