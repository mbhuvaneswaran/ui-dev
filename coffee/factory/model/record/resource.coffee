
main.factory 'Resource', [
  'FeatureToggle', 'Record',
  (FeatureToggle, Record) ->

    class Resource extends Record
      api:        'Resource'
      cookieHide: 'hiddenResources'
      idProperty: 'resourceId'

      constructor: ->
        super
        @xid = 'rsc' + @id

      fullName: =>
        @data.resourceName

      name: =>
        @data.resourceName

      postVisibilitySet: =>
        if not FeatureToggle.enabled[FT_DARK_NON_PROVIDER_CALENDARS] or
        @data.resourceTypeId is 1 # Room are hidden on calendar
          @visible = false

      replace: =>
        super
        @xid = 'rsc' + @id

      rscGroup: =>
        [null, 'Room', 'Equipment', 'Staff'][@data.resourceTypeId]
]
