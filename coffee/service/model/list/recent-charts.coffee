
main.service 'RecentCharts', [
  'List', 'RecentChart',
  (List, RecentChart) ->

    class RecentCharts extends List
      api:         'RecentCharts'
      recordClass: RecentChart

      constructor: ->
        super
        @load()

    new RecentCharts
]
