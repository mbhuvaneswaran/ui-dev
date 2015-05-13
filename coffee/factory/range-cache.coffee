
main.factory 'RangeCacheFactory', ->

  class RangeCache
    constructor: ->
      @ranges = []

    clear: =>
      empty_array @ranges

    uncovered: (min, max, fill_gaps=true) =>
      uncovered = [[min, max]]
      ranges = @ranges

      unless min < max
        throw new Error 'min should be less then max'

      for range in ranges
        for req, i in uncovered when req
          if req[0] >= range[0] and req[1] <= range[1]
            uncovered[i] = null
          else if req[0] < range[0] and req[1] > range[1]
            uncovered.push [range[1], req[1]]
            req[1] = range[0]
          else if req[0] < range[0] and req[1] <= range[1] and req[1] > range[0]
            req[1] = range[0]
          else if req[0] >= range[0] and req[1] > range[1] and req[0] < range[1]
            req[0] = range[1]

      uncovered = ([item[0], item[1]] for item in uncovered when item)

      if fill_gaps
        fillers = ([item[0], item[1]] for item in uncovered when item)
        tmp = []
        while ranges.length
          item = ranges.shift()
          for req, i in fillers when req
            if req[0] is item[1]
              item[1] = req[1]
              fillers[i] = null
              break
            if req[1] is item[0]
              item[0] = req[0]
              fillers[i] = null
              break

          if tmp.length and item[0] is (prev = tmp[tmp.length - 1])[1]
            prev[1] = item[1]
          else
            tmp.push item

        while tmp.length
          ranges.push tmp.shift()

        for req in fillers when req
          ranges.push req
        ranges.sort (a, b) ->
          return 1 if a[0] > b[0]
          -1

      uncovered
