
main.service 'TimeOffs', [
  'TimeOffsFactory', 'View',
  (TimeOffsFactory, View) ->

    MAX_DAY_BLOCK_SIZE = 120 # 3 month coverage for month view + preloads

    list = new TimeOffsFactory

    View.if 'update', ->
      list.loadRange View.range.preload..., MAX_DAY_BLOCK_SIZE

    list
]
