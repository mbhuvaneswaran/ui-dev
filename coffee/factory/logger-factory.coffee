LoggerFactory = main.factory 'LoggerFactory', [
  'LoggingServiceRepository', (LoggingServiceRepository) ->

    loggers = []
    
    getLogger : (enabled, location) ->
      logger = new Logger(!!enabled, location, LoggingServiceRepository)
      loggers.push logger

      logger

    setAllEnabled : (enabled) ->
      for logger in loggers
        logger.setEnabled(enabled)
]