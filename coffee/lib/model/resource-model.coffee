class ResourceModel
  @ROOM_RESOURCE: 1
  @EQUIPMENT_RESOURCE: 2
  @STAFF_RESOURCE: 3

  @getUpdateObject: (resource) ->
    {
      resourceName: resource.resourceName,
      resourceTypeId: resource.resourceTypeId,
      updatedBy: resource.updatedBy
    }