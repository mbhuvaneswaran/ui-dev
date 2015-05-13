main.service 'ProviderRepository', [
  '$http', ($http) ->

    defaultUrl = "/dashboard-calendar-ui/api/Provider"

    getDefaultUrl: ->
      defaultUrl

    getAllProviders: () ->
      url = "#{defaultUrl}"
      $http.get(url)
  ]