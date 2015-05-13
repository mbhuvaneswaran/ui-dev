class ErrorHandler
  @getStatus: (data, status) ->
    if status >= 400 and status < 500
      if data == null or data.message == null
        return 'Could not create resource'
      return data.message
    else if status >= 500
      return "A server error occurred"
    else
      return "An unknown error ocurred"