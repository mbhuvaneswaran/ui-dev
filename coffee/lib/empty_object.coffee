
empty_object = (objects...) ->
  for object in objects
    delete object[k] for own k of object
  null
