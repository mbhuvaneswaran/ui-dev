
empty_array = (arrays...) ->
  for array in arrays
    array.pop() while array.length
  null
