main.service 'PatientBalanceRepository', [
  '$http', 'UrlFor', ($http, UrlFor) ->

    defaultUrl = UrlFor.api('PatientPayment')

    getDefaultUrl: ->
      defaultUrl

    getBalance: (patientId) ->
      url = "#{defaultUrl}balance/#{patientId}"
      $http.get(url, {timeout: 5000})
  ]