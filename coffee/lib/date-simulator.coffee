## Used to setup a date simulation
## url ex:
## ?simulatedDate=2014-03-08&simulatedTime=12:15:05
## returns a simulated date with the given time
class DateSimulator
  simulatedDate = null
  _routeParams = null

  constructor: (routeParams) ->
    _routeParams = routeParams
    this.getUpdatedTime()

  getUpdatedTime: ->
    return if not _routeParams?
    
    if _routeParams.date? || _routeParams.time?
      _date = _routeParams.date or null
      _time = _routeParams.time or null
      use_date = true

      if _date? and !/^(\d){4}-(\d){2}-(\d){2}$/.test(_date)
        console.error "Invalid Date Format (YYYY-mm-dd)"
        use_date = false
      if _time? and !/^(\d){2}:(\d){2}:(\d){2}$/.test(_time)
        console.error "Invalid Time Format (hh:mm:ss)"
        use_date = false

      this.simulatedDate = new Date()

      if use_date
        if _date?
          this.simulatedDate.setDate 1 # prevent issues with being on 31st day
          this.simulatedDate.setFullYear(_date.substr(0,4))
          this.simulatedDate.setMonth(_date.substr(5,2)-1)
          this.simulatedDate.setDate(_date.substr(8, 2))

        if _time?
          this.simulatedDate.setHours(
            _time.substr(0,2), _time.substr(3,2), _time.substr(6,2), 0)

  hasSimulatedDate: ->
    this.simulatedDate?

  getSimulatedDate: ->
    this.getUpdatedTime()
    this.simulatedDate
