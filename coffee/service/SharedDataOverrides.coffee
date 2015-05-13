main.config(['$provide', ($provide) ->

  deferGetDecorator = ['$q', '$delegate', ($q, $delegate) ->
    loadDeferred = $q.defer()

    $delegate.setData = (data) ->
      loadDeferred.resolve(data)

    $delegate._getData = () -> loadDeferred.promise

    $delegate
  ]

  deferGet = (moduleName) ->
    $provide.decorator(moduleName, deferGetDecorator)



  deferGet 'userRepository'
  deferGet 'recentCharts'
  deferGet 'practice'
  deferGet 'privilegeRepository'
])
