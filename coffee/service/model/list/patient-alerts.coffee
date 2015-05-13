CalendarCtrl.service 'PatientAlerts', [
  'List', 'PatientAlert', 'UrlFor',
  (List, PatientAlert, UrlFor) ->

    class PatientAlerts extends List
      api:         'PatientAlerts'
      recordClass: PatientAlert

      constructor: ->
        super

      load: ( patientId ) ->
        url = UrlFor.api @api
        url += patientId
        super url

    new PatientAlerts
]