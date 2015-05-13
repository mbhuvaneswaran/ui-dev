
class Async
  consolidate: (count, callback) ->
    if typeof count is 'function'
      callback = count
      count = 1

    done   = 0
    errors = []

    fn = (err) ->
      done += 1
      errors.push(err) if err
      if done is fn.count
        switch errors.length
          when 0
            callback()
          when 1
            callback errors[0]
          else
            callback errors

    fn.count = count
    fn.add = (n=1) ->
      fn.count += n
      fn

    fn


  squash: (list, done_cb, iteration_fn) ->
    count   = 0
    errors  = []
    len     = list.length
    results = []

    iteration_callback = (err, response...) ->
      count += 1
      errors.push(err) if err?
      results.push response
      if count is len
        switch errors.length
          when 0
            done_cb null, results
          when 1
            done_cb errors[0], results
          else
            done_cb errors, results

    for item in list
      iteration_fn item, iteration_callback

    return

  wrapPromise: (promise, callback) ->
    promise.success (args...) ->
      callback null, args...

    promise.error (args...) ->
      callback args

    return
