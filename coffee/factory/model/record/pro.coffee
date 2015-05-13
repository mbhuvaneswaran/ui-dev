
CalendarCtrl.factory 'Pro', [
  'Record',
  (Record) ->

    class Pro extends Record
      api:        'Pro'
      cookieHide: 'hiddenProviders'
      idProperty: 'providerId'

      constructor: ->
        super
        @xid = 'pro' + @id

      fullName: =>
        @data.firstName + ' ' + @data.lastName

      name: =>
        @data.lastName + ', ' + @data.firstName

      replace: =>
        super
        @xid = 'pro' + @id

      rscGroup: ->
        'Providers'
]
