
CalendarCtrl.service 'FeatureToggle', [
  'List', 'Record',
  (List, Record) ->

    class ToggledFeature extends Record
      api:        'PracticeFeatures'
      idProperty: 'featureKey'

      constructor: (args...) ->
        if typeof args[0] is 'string'
          args[0] = featureKey: args[0]
        super args...

    class FeatureToggle extends List
      api:         'PracticeFeatures'
      recordClass: ToggledFeature

      constructor: ->
        @enabled = {}
        @if 'load', @loadSpecialValues
        super

      loadSpecialValues: =>
        empty_object @enabled
        for item in @data when not item.data.exclude
          @enabled[item.data.featureKey] = true
        return

    new FeatureToggle
]
