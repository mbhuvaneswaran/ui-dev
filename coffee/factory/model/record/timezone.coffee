
main.factory 'Timezone', [
  'Record',
  (Record) ->

    class Timezone extends Record
      api:        'Timezone'
      idProperty: 'timeZone'
]
