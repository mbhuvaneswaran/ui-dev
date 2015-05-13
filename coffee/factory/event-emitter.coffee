
CalendarCtrl.factory 'EventEmitter', [
  '$interval', '$timeout',
  ($interval, $timeout) ->

    ###
    A class used by EventEmitter to store and manage callbacks.

    @author greg.varsanyi@kareo.com
    ###
    class EventSubscriptions
      ###
      @property [object] names storage for subsctiptions per type
      ###
      constructor: ->
        @names = {}

      ###
      Emission logic

      @param [bool] sync truthy if synchronous
      @param [string] name event identifier
      @param [*] args... optional arguments to be passed to the callback fn
      @return [bool] indicates if at least one callback fn was called
      ###
      emit: (sync, name, args...) =>
        block = (@names[name] ?= {})
        callback_found = false
        block.fired = (block.fired or 0) + 1
        block.lastArgs = args
        callback_list = []
        for once in [0, 1]
          for id, callback of block[once] or {}
            if typeof callback is 'function'
              callback_found = true
              if once
                delete block[once][id]
              if sync
                callback args...
              else
                callback_list.push callback

        # asynchronous
        unless sync
          $timeout ->
            for callback in callback_list
              callback args...

        callback_found

      ###
      Calls the callback fn if the event was fired before (with the arguments of
      the last emission). Synchronous, will return after the callback is called.
      Used by EventEmitter.ifSync() and EventEmitter.if1Sync()

      @param [string] name event identifier
      @param [function] callback
      @return [bool] indicates if a callback fn was called
      ###
      instantCall: (name, callback) =>
        if @names[name]?.fired
          callback @names[name].lastArgs...
          return true
        false

      ###
      Calls the callback fn if the event was fired before (with the arguments of
      the last emission). Asynchronous, wraps the callback in $timeout with 0
      delay - will return before the callback is called.
      Used by EventEmitter.if() and EventEmitter.if1()

      @param [string] name event identifier
      @param [function] callback
      @return [bool] indicates if a callback fn was called
      ###
      lateCall: (name, callback) =>
        if @names[name]?.fired
          $timeout =>
            callback @names[name].lastArgs...
          return true
        false

      ###
      Registers one ore more new event subscriptions

      @param [string] names... event identifier(s)
      @param [bool] once indicates one-time subscription (if1 and on1)
      @param [function] callback
      @return [function] unsubscriber
      ###
      push: (names..., once, callback) =>
        events = @
        ids    = []
        once   = if once then 1 else 0
        for name in names
          @names[name] ?= {}
          block = (@names[name][once] ?= i: 0)
          block[block.i] = callback
          ids.push block.i
          block.i += 1

        unsubscribed = false

        # create empty unsubscriber
        fn = EventEmitter::unsubscriber()
        # add this event unsubscriber
        fn.add ->
          return false if unsubscribed
          unsubscribed = true
          for id in ids
            delete events.names[name][once][id]
          true
        fn


    check = (instance, names, fn, next) ->
      instance.events ?= new EventSubscriptions

      return false unless fn and typeof fn is 'function'
      for name, i in names
        continue if i is 0 and typeof name is 'boolean'
        return false unless name and typeof name is 'string'
      next()

    ###
    # EventEmitter

    @author greg.varsanyi@kareo.com

    This class is meant to be extended by classes that may emit events outside
    Angular controllers' $broadcast/$emit concept (like service-service
    communication).

    ## API
    1. __Classic event listener__
            instance.on('event'[, 'event2', ...], callback)
    2. __One-time event listener__
            instance.on1('event'[, 'event2', ...], callback)
    3. __Event listener with instant callback if the event happened before__
            instance.if('event'[, 'event2', ...], callback)
    4. __One-time event listener OR instant callback if the event happened
    before__
            instance.if1('event'[, 'event2', ...], callback)
    5. __Emit event__
            instance.emit('event'[, args...]) # args will be passed to callbacks
    6. __Check if event was emitted before__
            instance.emitted('event')
    7. __Unsubscribe__
            unsubscriber = instance.on('event', callback)
            unsubscriber() # callback won't get called on 'event'
    8. __Unsubscribe chain__
            unsubscriber = instance.on('event', callback)
            unsubscriber.add other_instance.if1('event2', callback)
            unsubscriber() # both subscriptions get removed

    ## Important notes
    - emit(), if() and if1() are guaranteed to be asynchronous, they will return
      before callbacks are triggered. If you want them triggered before, use
      emitSync(), ifSync and if1Sync()
    - Don't forget to unsubscribe when you destroy a scope. Not unsubscribing
      prevents garbage collection from running right and calling references on
      supposedly removed objects may lead to unexpected behavior.
    ###
    class EventEmitter

      ###
      Emit event, e.g. call all functions subscribed for the specified event.
      This is guaranteed to be asynchronous, callbacks are wrapped in $timeout
      with 0 delay, causing this function to return before they get executed.

      @param [string] name event identifier
      @param [*] args... optional arguments to be passed to the callback fn
      @return [bool] indicates if anything was called
      ###
      emit: (name, args...) =>
        if typeof name is 'boolean'
          sync = name
          name = args.shift()
        return false unless name and typeof name is 'string'
        (@events = @events or new EventSubscriptions).emit !!sync, name, args...

      ###
      Emit event, e.g. call all functions subscribed for the specified event.
      This is a synchronous call, callback functions will run before this
      function returns. Note that the callback functions may still contain
      async logic.

      @param [string] name event identifier
      @param [*] args... optional arguments to be passed to the callback fn
      @return [bool] indicates if anything was called
      ###
      emitSync: (name, args...) =>
        @emit true, name, args...

      ###
      Check if this even was emitted before by the object.
      If so, it returns an array of the arguments of last emission which is
      the "args..." part of the emit(name, args...) method.

      @param [string] name event identifier
      @return [bool/Array] false or Array of arguments
      ###
      emitted: (name) ->
        if (subscriptions = @events?.names[name])?.fired
          return subscriptions.lastArgs
        false

      ###
      Subscribe for 1 event in the future OR the last emission if there was one

      This is guaranteed to be asynchronous, e.g. even if the callback gets
      triggered instantly, because the event was emitted in the past, the
      callback is wrapped in a $timeout with 0 delay, causing this function to
      return before the callback gets called.

      @param [string] names... name(s) that identify event(s) to subscribe to
      @param [function] callback function to call on event emission
      @return [function] unsubscriber
      ###
      if1: (names..., callback) => check @, names, callback, =>
        caller = 'lateCall' # async
        if typeof names[0] is 'boolean'
          caller = 'instantCall' if names.shift() # sync

        remainder = []
        for name in names
          unless @events[caller] name, callback
            remainder.push name

        @events.push remainder..., 1, callback

      ###
      Subscribe for 1 event in the future OR the last emission if there was one

      This is synchronous, so in case the event was emitted in the past, the
      callback function will be called before this function returns.

      @param [string] names... name(s) that identify event(s) to subscribe to
      @param [function] callback function to call on event emission
      @return [function] unsubscriber
      ###
      if1Sync: (names..., callback) =>
        @if1 true, names..., callback

      ###
      Subscribe for future events AND the last emission if there was one

      This is guaranteed to be asynchronous, e.g. even if the callback gets
      triggered instantly, because the event was emitted in the past, the
      callback is wrapped in a $timeout with 0 delay, causing this function to
      return before the callback gets called.

      @param [string] names... name(s) that identify event(s) to subscribe to
      @param [function] callback function to call on event emission
      @return [function] unsubscriber
      ###
      if: (names..., callback) => check @, names, callback, =>
        caller = 'lateCall' # async
        if typeof names[0] is 'boolean'
          caller = 'instantCall' if names[0] # sync
          names.shift()

        for name in names
          @events[caller] name, callback

        @events.push names..., 0, callback

      ###
      Subscribe for future events AND the last emission if there was one

      This is synchronous, so in case the event was emitted in the past, the
      callback function will be called before this function returns.

      @param [string] names... name(s) that identify event(s) to subscribe to
      @param [function] callback function to call on event emission
      @return [function] unsubscriber
      ###
      ifSync: (names..., callback) =>
        @if true, names..., callback

      ###
      Subscribe for 1 event in the future

      @param [string] names... name(s) that identify event(s) to subscribe to
      @param [function] callback function to call on event emission
      @return [function] unsubscriber
      ###
      on1: (names..., callback) => check @, names, callback, =>
        @events.push names..., 1, callback

      ###
      Subscribe for events in the future

      @param [string] names... name(s) that identify event(s) to subscribe to
      @param [function] callback function to call on event emission
      @return [function] unsubscriber
      ###
      on: (names..., callback) => check @, names, callback, =>
        @events.push names..., 0, callback

      ###
      Get an empty unsubscriber function you can add unsubscibers to
      @example
        unsub = MyEventEmitterObject.unsubscriber()

        unsub.add $timeout(timed_fn, 100)
        unsub.add MyOtherEventEmitterObject.if('roar', lion_coming_fn)

        $scope.$on '$destroy', unsub

      @return [function] unsubscriber
      ###
      unsubscriber: ->
        attached  = {}
        increment = 0

        ###
        Calls all added functions and cancels $interval/$timeout promises
        @return: [null/bool] null = no added fn, true = all returned truthy
        ###
        fn = ->
          status = null
          for node of attached
            if typeof node is 'function'
              status = false unless node()
            else if node and typeof node is 'object' and node.then?
              if node.$$intervalId?
                status = false unless $interval.cancel node
              else if node.$$timeoutId?
                status = false unless $timeout.cancel node
          status

        fn.add = (unsubscriber) ->
          do (increment) ->
            del = ->
              delete attached[increment]

            attached[increment] = unsubscriber

            if unsubscriber and typeof unsubscriber is 'object'
              if unsubscriber.$$timeoutId? and unsubscriber.then?
                unsubscriber.then del
              else if unsubscriber.$$intervalId? and unsubscriber.finally?
                unsubscriber.finally del

          increment += 1
          return

        fn
]
