CalendarSetupResourceCtrl =
CalendarSetupCtrl.controller 'CalendarSetupResourceCtrl', [
  '$scope', '$http', '$timeout', '$routeParams', 'FeatureToggle',
  'LoggerFactory', 'ResourceRepository', 'Resources'
  ($scope, $http, $timeout, $routeParams, FeatureToggle,
  LoggerFactory, ResourceRepository, Resources) ->

    # Reference
    # $scope.appId

    if $scope.data.staffResources is undefined
      $scope.data.staffResources = []
    if $scope.data.rooms is undefined
      $scope.data.rooms = []
    if $scope.data.equipment is undefined
      $scope.data.equipment = []

    logger = LoggerFactory.getLogger(enabled=false, "ResourceCtrl")

    # event unsubscriber
    unsub = FeatureToggle.unsubscriber()
    $scope.$on '$destroy', unsub

    #############################################################
    ## SHARED DATA INTEGRATION HOOKS
    #############################################################
    integrationHookUpsertResource = ( resource_data ) ->
      id = resource_data.resourceId
      logger.trace( 'integrationHookUpsertResource', "id:#{id}")
      Resources.upsert( resource_data ) if Resources.data?.length >= 0

    integrationHookCutResource = ( resource_id ) ->
      logger.trace( 'integrationHookCutResource', "id:#{resource_id}")
      res = Resources.get resource_id
      Resources.cut( res ) if res

    #############################################################
    ## BROADCAST HANDLER
    #############################################################
    $scope.submit = (card, formData, form) ->
      $scope.formData.inputError = true if form.$invalid

      if form.$valid and card.type in ['resource', 'room', 'equipment']
        form.$setPristine()

        resource_type_id = $scope.getAppointmentResourceTypeId(card)

        if formData.submission is "update"
          $scope.updateResource(
            formData, resource_type_id)
        else if formData.submission is "delete"
          $scope.removeResource(
            formData, resource_type_id)
        else
          $scope.createResource(
            formData, resource_type_id)

    $scope.getAppointmentResourceTypeId = (card) ->
        if card.type is 'resource'
          resource_type_id = ResourceModel.STAFF_RESOURCE
        else if card.type is 'room'
          resource_type_id = ResourceModel.ROOM_RESOURCE
        else if card.type is 'equipment'
          resource_type_id = ResourceModel.EQUIPMENT_RESOURCE

    #############################################################
    ## CLICK HANDLERS
    #############################################################
    $scope.showCreateResource = (card) ->
      $scope.resetForm()
      $scope.formData.submission = "create"

      $scope.editor.title = card.button
      $scope.openEditor(card)

    $scope.showEditResource = (card, resource) ->
      $scope.resetForm()
      $scope.formData.submission = "update"
      $scope.formData.name = resource.resourceName
      $scope.formData.id = resource.resourceId

      label = card.type[0].toUpperCase() + card.type[1..-1]
      $scope.editor.title = "Edit " + label
      $scope.openEditor(card)

    #############################################################
    ## HTTP HANDLERS
    #############################################################
    unsub = FeatureToggle.if 'load', ->
      $scope.equipmentEnabled =
        FeatureToggle.enabled[FT_DARK_NON_PROVIDER_CALENDARS]
      $scope.featuresLoaded = true
      
    $scope.getResources = () ->
      ResourceRepository.getAllResources()
      .success((data) ->
        resources = data

        for resource in resources
          unless resource.deleted
            if resource.resourceTypeId is ResourceModel.STAFF_RESOURCE
              # ResourceData.staffResources.push resource
              $scope.data.staffResources.push resource
            else if resource.resourceTypeId is ResourceModel.ROOM_RESOURCE
              $scope.data.rooms.push resource
            else if resource.resourceTypeId is ResourceModel.EQUIPMENT_RESOURCE
              $scope.data.equipment.push resource
      ).error( (data, status) ->
        $scope.formData.submissionError = ErrorHandler.getStatus(data, status)
      )

    $scope.createResource = (formData, resource_type_id) ->
      ResourceRepository.createResource({
        resourceTypeId: resource_type_id,
        resourceName: formData.name
      })
        .success( (data) ->
          list = getResourceList(resource_type_id)
          list.push data
          $scope.closeEditor()

          integrationHookUpsertResource( data )
        )
        .error( (data, status) ->
          $scope.formData.submissionError = ErrorHandler.getStatus(data, status)
        )

    $scope.updateResource = (formData, resource_type_id) ->
      # find the resource
      resource = findResourceInList(formData.id, resource_type_id)

      $scope.cache_save = angular.copy(resource)
      resource.resourceName = formData.name

      ResourceRepository.updateResource({
        resourceName: formData.name,
        resourceTypeId: resource_type_id,
        resourceId: resource.resourceId
      })
      .success( (data) ->
        $scope.closeEditor()

        integrationHookUpsertResource( data )
      )
      .error( (data, status) ->
        resource.resourceName = $scope.cache_save.resourceName
        $scope.formData.submissionError = ErrorHandler.getStatus(data, status)
      )

    $scope.removeResource = (formData, resource_type_id) ->
      ResourceRepository.removeResource(formData.id)
      .success( (data) ->
        removeResourceFromList(formData.id, resource_type_id)
        $scope.closeEditor()

        integrationHookCutResource( formData.id )
      )
      .error( (data, status) ->
        $scope.formData.submissionError = ErrorHandler.getStatus(data, status)
      )

    findResourceInList = (id, resource_type_id) ->
      _list = getResourceList(resource_type_id)

      return null if(_list is null)

      for entry in _list
        if entry.resourceId is id
          _resource = entry

      return _resource

    removeResourceFromList = (id, resource_type_id) ->
      resource = findResourceInList(id, resource_type_id)

      if resource_type_id is ResourceModel.STAFF_RESOURCE
        $scope.data.staffResources =
          $scope.data.staffResources.filter (entry) ->
            entry.resourceId isnt id
      else if resource_type_id is  ResourceModel.ROOM_RESOURCE
        $scope.data.rooms = $scope.data.rooms.filter (entry) ->
          entry.resourceId isnt id
      else if resource_type_id is ResourceModel.EQUIPMENT_RESOURCE
        $scope.data.equipment = $scope.data.equipment.filter (entry) ->
          entry.resourceId isnt id

    getResourceList = (resource_type_id) ->
      _list = null

      if resource_type_id is ResourceModel.STAFF_RESOURCE
        _list = $scope.data.staffResources
      else if resource_type_id is  ResourceModel.ROOM_RESOURCE
        _list = $scope.data.rooms
      else if resource_type_id is ResourceModel.EQUIPMENT_RESOURCE
        _list = $scope.data.equipment

      return _list

    if not $scope.data.resourcesLoaded?
        $scope.data.resourcesLoaded = true
        $scope.getResources()
  ]


