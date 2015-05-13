main.service 'ResourceRepository', [
  '$http', ($http) ->

    defaultUrl = "/dashboard-calendar-ui/api/Resource/"

    getDefaultUrl: ->
      defaultUrl

    getAllResources: () ->
      $http.get(defaultUrl)

    createResource: (resource) ->
      $http.post(defaultUrl, {
        resourceTypeId: resource.resourceTypeId,
        resourceName: resource.resourceName
      })

    updateResource: (resource) ->
      $http.put(defaultUrl+resource.resourceId, resource)

    removeResource: (resourceId) ->
      $http.delete(defaultUrl + "#{resourceId}")
  ]