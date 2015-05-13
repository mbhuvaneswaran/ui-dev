CalendarCtrl.factory 'Record', [
  '$http', 'CookiePersistence', 'UrlFor','EventEmitter',
  ($http, CookiePersistence, UrlFor, EventEmitter) ->

    deep_inherit = (inf) ->
      saved = {}
      data = Object.create saved
      for k, v of inf
        if v and typeof v is 'object'
          [subdata] = deep_inherit v
          data[k] = subdata
        saved[k] = v
      [data, saved]

    class Record extends EventEmitter
      constructor: (data = {}) ->
        [@data, @saved] = deep_inherit data
        @id = @getId data

        # sets @visibility based on cookieHide
        if cookie_hide = @constructor::cookieHide
          @visible = not CookiePersistence.listHas cookie_hide, @id

      getId: (data) =>
        unless id_property = @constructor::idProperty
          throw new Error '::idProperty is missing'
        if typeof id_property is 'object'
          return (data[part] for part in id_property when data[part]).join '-'
        data[id_property]

      changed: (keys...) =>
        recursive_cmp = (data, saved, key_trail=[]) ->
          for own key, value of data
            if value and typeof value is 'object' and
            saved[key] and typeof saved[key] is 'object'
              (trail = angular.copy key_trail).push key
              recursive_cmp value, saved[key], trail
            else if value isnt saved[key]
              if key_trail.length
                (response = angular.copy key_trail).push key
                changed_keys.push response
              else
                changed_keys.push key

        changed_keys = []
        if keys.length
          for key in keys
            orig_key = key
            data     = @data
            saved    = @saved
            if typeof key is 'object'
              for subkey in key[0 ... key.length - 1]
                if data and typeof data is 'object' and data[subkey]?
                  data = data[subkey]
                else
                  data = null

                if saved and typeof saved is 'object' and saved[subkey]?
                  saved = saved[subkey]
                else
                  saved = null
              key = key[key.length - 1]

            if data?[key] and typeof data[key] is 'object' and
            saved?[key] and typeof saved[key] is 'object'
              trail = orig_key
              unless typeof orig_key is 'object'
                trail = [orig_key]
              recursive_cmp data[key], saved[key], trail
            else if data?.hasOwnProperty(key) and
            (not saved?.hasOwnProperty(key) or data[key] isnt saved[key])
              changed_keys.push orig_key
        else
          recursive_cmp @data, @saved

        if changed_keys.length
          changed_keys.sort (a, b) ->
            a = a.join('.') if typeof a is 'object'
            b = b.join('.') if typeof a is 'object'
            return 1 if a > b
            - 1
          return changed_keys
        false

      copyData: ->
        result = {}
        result[k] = v for k, v of @saved
        result[k] = v for own k, v of @data
        result

      entity: =>
        @copyData()

      replace: (data) =>
        [@data, @saved] = deep_inherit data
        @id = @getId @data

      revert: (keys...) =>
        if keys.length
          deep_ref = (obj, keys) ->
            if keys.length is 1
              return obj[keys]
            deep_ref obj[keys[0]], keys[1..]

          if changed = @changed keys...
            for item in changed
              if typeof item is 'object'
                data = deep_ref @data, item[0 ... item.length - 1]
                delete data[item[item.length - 1]]
              else
                delete @data[item]
        else
          @replace @saved
        return

      save: (data, id, callback) =>
        if typeof id is 'function'
          callback = id
          id = null

        @saving = true

        method = 'post'
        url = UrlFor.api @api, url
        if id
          method = 'put'
          url += id

        req = $http[method] url, data

        req.success (data) =>
          @saving = false
          @replace data
          callback?()

        req.error (data, status, headers, config) =>
          @saving = false
          console.error? 'error', arguments
          alert 'Failed to save'
          callback? arguments

      load: (url_or_query_params) ->
        if url = url_or_query_params
          if typeof url_or_query_params is 'object'
            url = UrlFor.api @api, url_or_query_params
        else
          url = UrlFor.api @api

        req = $http.get url

        req.success (data, args...) =>
          @replace data
          @emitSync 'load', data, args...
        req.error (args...) =>
          @emitSync 'load-error', args...
]
