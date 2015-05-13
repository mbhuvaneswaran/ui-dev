
main.service 'UrlFor', [
  '$location',
  ($location) ->
    base_url = '/dashboard-calendar-ui'
    base_payments_url = '/payments-ui'

    apis =
      Appt:             base_url + '/api/Appointment/'
      ApptConflict:     base_url + '/api/Appointment/conflicts/'
      ApptReason:       base_url + '/api/AppointmentReason/'
      BootStrap:        base_url + '/api/BootStrap/'
      CustomHoliday:    base_url + '/api/Holidays/custom/'
      DailyApptCount:   base_url + '/api/Appointment/counts/'
      PracticeFeatures: base_url + '/api/FeatureToggle'
      HolidayInstance:  base_url + '/api/Holidays/'
      Location:         base_url + '/api/ServiceLocation/'
      ObservedHoliday:  base_url + '/api/Holidays/observed/'
      OfficeHr:         base_url + '/api/OfficeHours/'
      Patient:          base_url + '/api/Patient/'
      PatientPayment:   base_payments_url + '/api/PatientPayment/'
      Practice:         base_url + '/api/Practice/'
      Pref:             base_url + '/api/Practice/setting/'
      Privilege:        base_url + '/api/Privileges/'
      Pro:              base_url + '/api/Provider/'
      RecentChart:      base_url + '/api/User/recentcharts'
      Resource:         base_url + '/api/Resource/'
      SynchronizedAppt: base_url + '/api/Appointment/synchronized/'
      TaskAlert:        base_url + '/api/OutstandingTasks'
      TimeOff:          base_url + '/api/TimeOffs/'
      Timezone:         base_url + '/api/Practice/timezones/'
      User:             base_url + '/api/User/'
      PatientAlert:     base_url + '/api/Patient/Alert/'

    get_base_url = ->
      if $location.absUrl().indexOf(base_url) is -1 then '' else base_url

    get_base_payments_url = ->
      base_payments_url

    get_options = (options) ->
      if options
        switch typeof options
          when 'object'
            parts = for k, v of options
              encodeURIComponent(k) + '=' + encodeURIComponent v
            return '?' + parts.join '&'
          when 'string'
            return '?' + options
      ''

    api: (name, query_params) ->
      if name.substr(name.length - 1) is 's'
        name = name.substr 0, name.length - 1
      apis[name] + get_options query_params

    calendar: (query_params) ->
      get_base_url() + '/#/calendar' + get_options query_params

    dashboard: ->
      get_base_url() + '/#/dashboard'

    calendarSetup: (query_params) ->
      get_base_url() + '/#/calendar-setup' + get_options query_params

    officeHoursSetup: (query_params) ->
      get_base_url() +
      '/#/calendar-setup/office-hours-setup' + get_options query_params

    logout: ->
      '/signout'

    ehrTasksOpenNotes: ->
      '/messages/show_open_notes'

    ehrFacesheet: (patientId) ->
      "/EhrWebApp/patients/viewFacesheet/#{patientId}"

    ehrDemographics: (patientId) ->
      "/EhrWebApp/patients/viewDemographics/#{patientId}"

    patientPaymentLink: (patientId, appointmentId) ->
      get_base_payments_url() +
        "/#/payment/#{patientId}?appointmentId=#{appointmentId}"

    ehrNewNoteLinkUpdated: ( appointment ) ->
      "/patients/#{ appointment.patientSummary.patientId }/notes/new?" +
      "appointment_id=#{ appointment.appointmentId }"

    freeTrialLink: ->
      'http://go.kareo.com/web-free-trial-in-app.html' +
      '?utm_source=Converged&utm_medium=InApp&utm_campaign=BalanceOnDashboard'

    getBaseUrl: get_base_url

    locationFormat: (path) ->
      path.replace '/#', ''

]
