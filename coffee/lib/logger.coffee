class Logger
  enabled = consoleEnabled = false
  loggingService = null

  # where is this logger used?
  location = null

  severity = {
    trace : 1
    debug : 2
    info : 3
    warn : 4
    error : 5
  }

  constructor : (enabled, location, loggingService) ->
    this.enabled = enabled
    this.loggingService = loggingService
    this.location = location

  setEnabled : (enabled) ->
    this.enabled = enabled

  setConsoleEnabled : (enabled) ->
    this.consoleEnabled = enabled

  # alias for trace
  log : (message...) ->
    this.trace(message)

  trace : (message...) ->
    this.writeLog(message, severity.trace)

  debug : (message...) ->
    this.writeLog(message, severity.debug)

  info : (message...) ->
    this.writeLog(message, severity.info)

  warn : (message...) ->
    this.writeLog(message, severity.warn)

  error : (message...) ->
    this.writeLog(message, severity.error)

  # write to an output, if the constraints are met
  writeLog : (message, severity) ->
    message.push "in #{this.location}"
    console.log message.toString() if this.consoleEnabled
    this.loggingService.createLog(severity, message.toString()) if this.enabled

