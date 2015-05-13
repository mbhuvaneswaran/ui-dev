
main.directive "validInteger", ->
  require: 'ngModel'

  scope:
    integerMax: '@'
    integerMin: '@'

  link: (scope, element, attr, ctrl) ->
    validate = (viewValue) ->
      clean = ''
      for char in String(viewValue).split ''
        unless (n = Number char) is 0 or n is 1 or 1 < n < 10
          break if clean.length
        else
          clean += char

      if scope.integerMin
        if clean.length and Number(clean) < Number scope.integerMin
          invalid = true

        while clean.length and Number(clean) > Number scope.integerMax
          clean = clean.substr 0, clean.length - 1

      unless clean.length
        invalid = true

      unless clean is viewValue
        ctrl.$viewValue = clean
        ctrl.$render()

      ctrl.$setValidity 'required', not (invalid or clean.length < 1)

      clean


    ctrl.$parsers.unshift validate
    ctrl.$formatters.unshift validate