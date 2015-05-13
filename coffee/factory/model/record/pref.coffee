
main.factory 'Pref', [
  'Record',
  (Record) ->

    class Pref extends Record
      api:        'Pref'
      idProperty: 'name'

      save: (callback) =>
        data =
          name:  @data.name
          value: @data.value

        super data, callback
]
