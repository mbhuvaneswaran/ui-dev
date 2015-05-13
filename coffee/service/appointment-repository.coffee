main.service 'AppointmentRepository', [
  '$http', ($http) ->

    defaultUrl = "/dashboard-calendar-ui/api/Appointment/"

    getDefaultUrl: ->
      defaultUrl

    getAllAppointments: (appointmentQuery) ->
      url = defaultUrl + this.getQueryString(appointmentQuery)
      $http.get(url)

    createAppointment: (appointment) ->
      $http.post(defaultUrl, appointment)

    createAppointmentOccurrenceException: (
      appointmentId, occurrenceId, newAppointmentId) ->
      url = "#{defaultUrl}old/#{appointmentId}/new/#{newAppointmentId}/exception/#{occurrenceId}"
      $http.post(url)

    createAppointmentResource: (appointmentId, resourceId) ->
      url = "#{defaultUrl}#{appointmentId}/resource/#{resourceId}"
      $http.post(url)

    removeAppointmentResource: (appointmentId, resourceId) ->
      url = "#{defaultUrl}#{appointmentId}/resource/#{resourceId}"
      $http.delete(url)

    updateAppointmentStatus: (
      appointmentId, appointmentStatusId, occurrenceId) ->
      url = "#{defaultUrl}#{appointmentId}/status"
      $http.put(url, {
        appointmentStatus: appointmentStatusId,
        occurrenceId: occurrenceId
      })

    getQueryString: (appointmentQuery) ->
      string = ""

      append = (string, piece) ->
        string += '&' if string.length > 0
        string += piece
        return string

      if appointmentQuery.providerId?
        string = append(string, 'providerId=' + appointmentQuery.providerId)
      if appointmentQuery.patientId?
        string = append(string, 'patientId=' + appointmentQuery.patientId)
      if appointmentQuery.deleted?
        string = append(string, 'deleted=' + appointmentQuery.deleted)
      if appointmentQuery.maxDaysPerPage?
        string = append(string,
          'maxDaysPerPage=' + appointmentQuery.maxDaysPerPage)
      if appointmentQuery.pageToken?
        string = append(string, 'pageToken=' + appointmentQuery.pageToken)
      if appointmentQuery.maxDate?
        string = append(string, 'maxDate=' + appointmentQuery.maxDate)
      if appointmentQuery.minDate?
        string = append(string, 'minDate=' + appointmentQuery.minDate)
      if appointmentQuery.appointmentUuid?
        string = append(string,
          'appointmentUuid=' + appointmentQuery.appointmentUuid)

      return '?' + string
  ]