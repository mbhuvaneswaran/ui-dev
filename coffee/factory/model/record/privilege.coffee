
main.factory 'Privilege', [
  'Record'
  (Record) ->
    class Privilege extends Record
      api: 'Privilege'
      idProperty: ['id', 'accessType']

]
