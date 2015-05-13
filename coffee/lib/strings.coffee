
class Strings
  dashToCamel: (input) ->
    input.toLowerCase().replace /-(.)/g, (match, group1) ->
      group1.toUpperCase()

  dashToSpace: (input) ->
    input.replace /-/g, ' '

  camelToDash: (str) ->
    str.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase()

  leftPad: (char, string, size) ->
    newString = String(string)
    while newString.length < size
      newString = char + newString
    newString