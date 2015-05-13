
main.service 'Timezones', [
  'Timezone', 'List',
  (Timezone, List) ->

    class Timezones extends List
      api:         'Timezones'
      recordClass: Timezone
      sortBy:      'sortOrder'

      constructor: ->
        super
        @load {}

    new Timezones
]