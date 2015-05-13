
main.service 'Appts', [
  'ApptsFactory', 'View',
  (ApptsFactory, View) ->

    list = new ApptsFactory

    list.setPseudo()

    View.if 'update', ->
      if View.view and View.view isnt CALENDAR__VIEW__MONTH
        list.loadRange View.range.render...

    list
]
