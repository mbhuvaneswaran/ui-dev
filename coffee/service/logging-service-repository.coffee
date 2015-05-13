main.factory 'LoggingServiceRepository', [
  '$http', ($http) ->

    defaultUrl = "/dashboard-calendar-ui/api/Logger/"

    getDefaultUrl: ->
      defaultUrl

    createLog : (severity, message) ->
      $http.post(defaultUrl, {
        severity : severity,
        message : message
      })
  ]