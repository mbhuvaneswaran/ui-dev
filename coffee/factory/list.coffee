
CalendarCtrl.factory 'List', [
  '$http', 'CookiePersistence', 'EventEmitter', 'Record', 'UrlFor',
  ($http, CookiePersistence, EventEmitter, Record, UrlFor) ->

    class List extends EventEmitter
      constructor: ->
        @data  = []
        @dicts = {}
        @pendingHttp = 0

        # updates cookieHide with new visibility data
        if cookie_hide = @constructor::recordClass?::cookieHide
          @on 'load', 'update', =>
            CookiePersistence.propertyToList cookie_hide, @data, 'visible', true
            for record in @data
              record.postVisibilitySet?()

      _signiture: (args, next) =>
        params = (v for k, v of args)
        unless typeof params[params.length - 1] is 'function'
          params.push ->
        next.apply @, params

      clear: =>
        @data.pop() while @data.length
        empty_object @dicts

      cut: (record) =>
        found = false
        for item, idx in list = @data
          if item.id is record.id
            found = true
            tmp_container = []
            while list.length > idx + 1
              tmp_container.push list.pop()
            list.pop()
            while tmp_container.length
              list.push tmp_container.shift()
            break
        found

      delete: (args...) => @_signiture args, (deletables..., callback) ->
        api = UrlFor.api @api

        # if ::collectionSupport.delete
        ### This is likely not built for a real bulk delete API,
            probably just needs list of id's
        if @constructor::collectionSupport?.delete
          @pendingHttp += 1
          promise = $http.delete api, (record.entity() for record in deletables)
          return Async::wrapPromise promise, (err, result...) =>
            @pendingHttp -= 1
            unless err
              @cut(item) for item in deletables
            callback err, result
        ###

        # if not ::collectionSupport.delete
        finished = (err, results) =>
          @refresh() unless err and err.length is results.length
          callback err, results

        Async::squash deletables, finished, (record, iteration_callback) =>
          unless record.id? or record.id is 'pseudo'
            return iteration_callback new Error 'record.id missing: ' + record

          deleteId = record.id
          if typeof deleteId is 'string' # handle composite id
            deleteId = deleteId.split('-')[0]

          @pendingHttp += 1
          Async::wrapPromise $http.delete(api + deleteId), (err, result...) =>
            @pendingHttp -= 1
            @cut(record) unless err
            iteration_callback err, result...

      create: (data) =>
        new @constructor::recordClass data

      get: (id) =>
        id = String id
        try
          for item in @data
            return item if String(item.id) is id
        catch err
          console.error 'this', @
          console.error 'data', @data
          throw err

        null

      directLoad: (items) =>
        @upsert(item) for item in items
        @hasLoadError = null
        @hasLoaded = true
        @refresh 'load', items

      directLoadError: (err) =>
        @hasLoadError = err or true
        @hasLoaded = true
        @emitSync 'load-error'

      load: (url_or_query_params, callback) =>
        if typeof url_or_query_params is 'function'
          callback = url_or_query_params
          url_or_query_params = null
        if url = url_or_query_params
          if typeof url_or_query_params is 'object'
            url = UrlFor.api @api, url_or_query_params
        else
          url = UrlFor.api @api

        @pendingHttp += 1
        Async::wrapPromise $http.get(url), (err, data, others...) =>
          @pendingHttp -= 1
          if err
            @directLoadError err
          else
            @directLoad data[@listProperty] or data
          callback? err, data, others...

      refresh: (event='update', args...) =>
        @sort()
        empty_object @dicts
        @emitSync event, args...

      reload: (args...) =>
        @clear()
        @load args...

      save: (args...) => @_signiture args, (savables..., callback) ->
        api = UrlFor.api @api

        # if ::collectionSupport.save
        if method = @constructor::collectionSupport?.save
          method = method.toLowerCase()
          method = 'put' unless method is 'post'
          @pendingHttp += 1
          promise = $http[method] api, (record.entity() for record in savables)
          return Async::wrapPromise promise, (err, result...) =>
            @pendingHttp -= 1
            unless err
              @upsert(item) for item in result[0]
              @emitSync 'update'
            callback err, result

        # if not ::collectionSupport.save
        finished = (err, results) =>
          @refresh() unless err and err.length is results.length
          callback err, results

        Async::squash savables, finished, (record, iteration_callback) =>
          method = 'post'
          url    = api
          if record.id and record.id isnt 'pseudo'
            method = 'put'
            id = record.id
            if typeof id is 'string' # handle composite id
              id = id.split('-')[0]
            url += id

          @pendingHttp += 1
          promise = $http[method] url, record.entity()
          Async::wrapPromise promise, (err, result...) =>
            @pendingHttp -= 1
            @upsert(result[0]) unless err
            iteration_callback err, result...

      # Will look for
      # sort:
      #   property: ['recurrenceRule', ''] # string | [properties...].join(' ')
      #   method: null  # fn ref. Mutually exclusive with property
      #   desc: false
      #   type: 'natural' # natural | byte | number
      sort: (sort_by) =>
        sort_by ?= @constructor::sortBy
        return unless sort_by?

        if typeof sort_by is 'string' or sort_by instanceof Array
          sort_by =
            property: sort_by

        natural = (value) ->
          String(value).toLowerCase()

        @data.sort (a, b) ->
          return unless a? and b?
          if sort_by.method
            a = a[sort_by.method]?()
            b = b[sort_by.method]?()
          else if typeof (property = sort_by.property) is 'string'
            a = a.data[property]
            b = b.data[property]
          else if property instanceof Array
            a = (a.data[part] for part in property when a.data[part]).join ' '
            b = (b.data[part] for part in property when b.data[part]).join ' '

          if sort_by.type is 'number'
            a ?= 0
            b ?= 0
          else
            a ?= ''
            b ?= ''

          switch sort_by.type
            when 'natural'
              a_priority = natural(a) > natural b
            when 'number'
              a_priority = Number(a) > Number b
            else
              a_priority = a > b

          a_priority = not a_priority if sort_by.desc

          return 1 if a_priority
          -1

      findBy: (key, value) =>
        return unless key? and value?

        @dicts ?= {}

        if @dicts[key]
          return @dicts[key][value]

        @dicts[key] = hash = {}
        for item in @data
          (hash[item.data[key]] ?= []).push item

        hash[value]

      upsert: (info) =>
        if info instanceof Record
          # NOTE: A dictionary of data should be passed. Use record.cloneData()
          # to get it. Make sure you update your reference to the record using
          # this the array that's returned by this method. Like this:
          #   [record, is_new] = MyList.upsert record.cloneData()
          throw new Error 'Record passed in. Read coffee/factory/list.coffee ' +
                          '::upsert() notes'

        empty_object @dicts
        new_record = false
        if record = @get @constructor::recordClass::getId info
          record.replace info
        else
          @data.push record = new @constructor::recordClass info
          new_record = true

        [record, new_record]
]
