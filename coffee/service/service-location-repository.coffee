main.service 'ServiceLocationRepository', [
  '$http', ($http) ->

    defaultUrl = "/dashboard-calendar-ui/api/ServiceLocation/"

    getDefaultUrl: ->
      defaultUrl

    getAllServiceLocations: () ->
      url = "#{defaultUrl}"
      $http.get(url)
  ]