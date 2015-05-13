
CalendarCtrl.directive 'datepicker', ['timez', '$window', (timez, $window) ->

  default_format = 'MM/DD/YYYY'

  linkFunction = (scope, iElement, iAttrs) ->

    picker = null

    if iElement.length is 1

      input = iElement[0]

      if scope.minDateMs
        controlMinDate = new Date Number scope.minDateMs

      fieldToUpdate = iAttrs.datepickerModel
      date_format = if iAttrs.format then iAttrs.format else default_format

      getFieldToUpdate = ->
        if /\./.test fieldToUpdate
          updateField = fieldToUpdate.split('.')
          field = scope.$parent[updateField[0]][updateField[1]]
        else
          field = scope.$parent[fieldToUpdate]
        field

      picker = new Pikaday
        field: input
        defaultDate: new Date scope.$parent[fieldToUpdate] * 1000
        setDefaultDate: true
        childOf: scope.childOf or undefined
        minDate: controlMinDate
        showWeekNumber: true
        format : scope.format or undefined
        onOpen: () ->
          picker.setDate(scope.datepickerModel,true);
          return
        onSelect: (date) ->

          tz = timez [date.getFullYear(), date.getMonth(), date.getDate()]

          if /\./.test fieldToUpdate
            updateField = fieldToUpdate.split('.')
            scope.$parent[updateField[0]][updateField[1]] =
              tz.utc().format date_format
          else
            scope.$parent[fieldToUpdate] = tz.utc().format date_format
          scope.$parent.$apply(iAttrs.onselect)

      input.datePicker = picker
      if scope.watchMinDateValue?
        scope.$parent.$watch scope.watchMinDateValue, ->
          min = new Date Number scope.minDateMs
          picker.gotoDate min
          picker.setMinDate min
          return

    iElement.bind('blur', ->
      picker.hide()
    )

    iElement.bind('focus', ->
      newDate = DateConverter::parsePickerFormat getFieldToUpdate(), date_format
      return unless newDate
      picker.gotoDate(newDate)
    )

    angular.element($window).bind 'resize', ->
      if picker.isVisible()
        picker.hide()
        picker.show()

  pikaday =
    link: linkFunction,
    scope:
      datepickerModel: '='
      childOf: '@'
      minDateMs: '@'
      watchMinDateValue: '@'

]
