main.service 'AppointmentReasonRepository', [
  '$http', '$timeout',
  ($http, $timeout) ->

    defaultUrl = '/dashboard-calendar-ui/api/AppointmentReason/'

    getDefaultUrl: ()->
      defaultUrl

    getAllAppointmentReasons: () ->
      $http.get(defaultUrl)

    createAppointmentReason: (appointmentReason) ->
      $http.post(defaultUrl, appointmentReason)

    updateAppointmentReason: (appointmentReason, appointmentReasonId) ->
      $http.put(defaultUrl+appointmentReasonId,
        appointmentReason)

    removeAppointmentReason: (appointmentReasonId) ->
      $http.delete(defaultUrl +
        "#{appointmentReasonId}")
  ]