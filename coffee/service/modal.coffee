
main.service 'Modal', [
  '$timeout',
  ($timeout) ->

    name = off_canvas = null

    off_canvas_completed = false

    off_canvas_open_delay  = 400
    off_canvas_close_delay = 200


    # modal related methods
    open: (_name) ->
      name = _name

    close: ->
      name = null
      @hideOffCanvas()

    isOpen: ->
      !!name

    whichModal: ->
      name

    isModal: (modal_to_check) ->
      name is modal_to_check


    # off-canvas related methods
    showOffCanvas: (callback) ->
      off_canvas = true

      $timeout ->
        off_canvas_completed = true
        callback?()
      , off_canvas_open_delay

    hideOffCanvas: (callback) ->
      off_canvas_completed = false

      $timeout ->
        off_canvas = false
        callback?()
      , off_canvas_close_delay

    offCanvasIsVisible: ->
      !!off_canvas

    offCanvasCompleted: ->
      off_canvas_completed
]
