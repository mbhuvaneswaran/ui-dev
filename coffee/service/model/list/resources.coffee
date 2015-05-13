
main.service 'Resources', [
  '$cookieStore', 'List', 'Resource',
  ($cookieStore, List, Resource) ->

    resource_types =
      room:      1
      equipment: 2
      staff:     3

    class Resources extends List
      api:         'Resources'
      recordClass: Resource
      sortBy:      'resourceName'

      findByResourceType: (res_type) =>
        type = resource_types[res_type]
        item for item in @data when item.data.resourceTypeId is type

    new Resources
]
