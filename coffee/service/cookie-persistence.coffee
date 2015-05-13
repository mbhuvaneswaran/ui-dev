
CalendarCtrl.service 'CookiePersistence', [
  '$cookieStore',
  ($cookieStore) ->

    get_list = (list_name) ->
      if typeof (list = $cookieStore.get(list_name) or []) isnt 'object'
        list = []
      list

    listDelete: (list_name, id) =>
      return if @readOnly

      list = for item in get_list list_name
        found = true if String(item) is String id
        item
      return false unless found
      $cookieStore.put list_name, if list.length then list else null
      true

    listUpsert: (list_name, id) =>
      return if @readOnly

      list = []
      for item in get_list list_name
        return false if String(item) is String id
        list.push item
      list.push id
      $cookieStore.put list_name, list
      true

    listHas: (list_name, id) ->
      for item in get_list(list_name) when String(item) is String id
        return true
      false

    propertyToList: (list_name, elements, property, negate) =>
      return if @readOnly

      filter = (item) ->
        if negate then not item[property] else !!item[property]

      list = (item.id for item in elements when filter(item))
      $cookieStore.put list_name, list
]
