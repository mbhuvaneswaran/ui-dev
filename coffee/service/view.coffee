
CalendarCtrl.service 'View', [
  '$cookieStore', '$location', '$rootScope', '$timeout', 'CanvasPosition',
  'CookiePersistence', 'Prefs', 'Pros', 'Resources', 'WebTracking', 'timez',
  ($cookieStore, $location, $rootScope, $timeout, CanvasPosition,
   CookiePersistence, Prefs, Pros, Resources, WebTracking, timez) ->

    default_view = CALENDAR__VIEW__HORIZONTAL_DAY

    available_views = [CALENDAR__VIEW__MONTH, CALENDAR__VIEW__HORIZONTAL_DAY,
                       CALENDAR__VIEW__VERTICAL_DAY, CALENDAR__VIEW__WEEK]

    hidden_days = 'hiddenDays'

    LAST_CALENDAR_VIEW = 'lastCalendarView'
    ZOOM_LEVEL         = 'zoomLevel'

    saved_zoom_level = Math.round $cookieStore.get ZOOM_LEVEL
    zoom_grades = (Math.round(Math.pow(2, i / 2) * 25) * .01 for i in [4 .. 12])

    (preload_range = []).tz = []
    (render_range  = []).tz = []
    (visible_range = []).tz = []

    url_formats = {}
    url_formats[CALENDAR__VIEW__HORIZONTAL_DAY] = 'h:mma_MMM_D,_YYYY_(Z)'
    url_formats[CALENDAR__VIEW__MONTH]          = 'MMM_YYYY'
    url_formats[CALENDAR__VIEW__VERTICAL_DAY]   = 'h:mma_MMM_D,_YYYY_(Z)'
    url_formats[CALENDAR__VIEW__WEEK]           = 'h:mma,_\\w\\e\\e\\k_\\o\\f' +
                                                  '_D_MMM_YYYY_(Z)'

    defaults = {}
    defaults[CALENDAR__VIEW__HORIZONTAL] =
      emPx:          13
      gradeHeight:   6
      apptHeight:    4
      apptMinHeight: 2.5
    defaults[CALENDAR__VIEW__VERTICAL] =
      emPx: 16

    update_exceptions = (view, time) ->
      unless view in available_views
        throw new Error 'invalid view: ' + view
      unless 2 < time < new Date().getTime() / 1000 + 631152000 # 20 yrs
        throw new Error 'invalid time: ' + time

      if Pros.countVisible() > CALENDAR__VIEW__DAY_LAYOUT_TOGGLE
        if view is CALENDAR__VIEW__VERTICAL_DAY
          view = CALENDAR__VIEW__HORIZONTAL_DAY
      else
        if view is CALENDAR__VIEW__HORIZONTAL_DAY
          view = CALENDAR__VIEW__VERTICAL_DAY

      view


    class View extends CanvasPosition # + EventEmitter
      HORIZONTAL_DAY: CALENDAR__VIEW__HORIZONTAL_DAY
      MONTH:          CALENDAR__VIEW__MONTH
      VERTICAL_DAY:   CALENDAR__VIEW__VERTICAL_DAY
      WEEK:           CALENDAR__VIEW__WEEK

      HORIZONTAL:     CALENDAR__VIEW__HORIZONTAL
      VERTICAL:       CALENDAR__VIEW__VERTICAL

      constructor: ->
        super

        Pros.if 'load', 'update', @providerUpdate
        Resources.if 'load', 'update', @providerUpdate

        unless CookiePersistence.listHas hidden_days, 'X'
          CookiePersistence.listUpsert(hidden_days, id) for id in ['X', 6, 0]

        @updateFromUrl()

        $rootScope.$on '$routeUpdate', =>
          @updateFromUrl() unless @locationUpdating

        # boot
        Prefs.if1 'load', => Pros.if1 'load', @updateFromUrl

      locationUpdating: 0

      providerUpdate: =>
        if read_only_pro = @readOnlyProvider
          for pro in Pros.data
            pro.visible = pro.id is read_only_pro
          for rsc in Resources.data
            rsc.visible = false

        if @view is CALENDAR__VIEW__WEEK
          Pros.ready = !!Pros.selectedProviderId
        else if @view
          Pros.ready = Resources.hasLoaded and Pros.hasLoaded
          @update @view, @time # will trigger horiz/vert toggle if needed

        if @days?.length
          CookiePersistence.propertyToList hidden_days, @days, 'visible', true

      range:
        preload: preload_range
        render:  render_range
        visible: visible_range

      days: for i in [1 .. 7]
        id:      i % 7
        name:    moment().day(i).format 'dddd'
        visible: not CookiePersistence.listHas hidden_days, i % 7

      columns: =>
        count = -1
        src = (week = @view is CALENDAR__VIEW__WEEK) and @days or
              Pros.withResources()
        for item in src when item.visible
          item.visibleId = (count += 1)
          item.title = week and item.tz?.format('ddd MMM DD') or item.name?()
          item

      rangeUpdate: =>
        tz_to_time = =>
          for k, v of @range
            v[0] = v.tz[0].unix()
            v[1] = v.tz[1].unix()
          return

        time_to_tz = =>
          for k, v of @range
            v.tz[0] = timez v[0] * 1000
            v.tz[1] = timez v[1] * 1000
          return

        now = (new Date).getTime() / 1000

        switch @view
          when CALENDAR__VIEW__HORIZONTAL_DAY
            unless @updateMetrics()
              visible_range[0] = preload_range[0] = render_range[0] = @time
              visible_range[1] = preload_range[1] = render_range[1] = @time + 1
              time_to_tz()
              return $timeout @rangeUpdate, 10

            span = @visibleSpan
            left = Math.floor @time - span / 5

            visible_range[0] = left
            visible_range[1] = left + span
            preload_range[0] = render_range[0] = left - span
            preload_range[1] = render_range[1] = left + span * 2
            time_to_tz()
            @onCurrentTime = visible_range[0] <= now < visible_range[1]

          when CALENDAR__VIEW__MONTH
            pos = @tz.startOfMonth()
            next = pos.nextMonth()
            intended_range = [pos.unix(), next.unix()]
            pos = pos.prevDay(day) if (day = pos.day()) > 0
            next = next.nextDay(7 - day) if (day = next.day()) > 0

            visible_range.tz[0] = render_range.tz[0] = pos
            visible_range.tz[1] = render_range.tz[1] = next
            preload_range.tz[0] = pos.prevMonth()
            preload_range.tz[1] = pos.nextMonth 2
            tz_to_time()
            @onCurrentTime = intended_range[0] <= now < intended_range[1]

          when CALENDAR__VIEW__WEEK, CALENDAR__VIEW__VERTICAL_DAY
            @updateMetrics()
            step  = 7
            start = 'startOfWeek'
            if @view is CALENDAR__VIEW__VERTICAL_DAY
              step  = 1
              start = 'startOfDay'

            preload_range.tz[0] = (pos = @tz.prevDay(step)[start]())
            pos = pos.nextDay(step)[start]()
            visible_range.tz[0] = render_range.tz[0] = pos
            pos = pos.nextDay(step)[start]()
            visible_range.tz[1] = render_range.tz[1] = pos
            pos = pos.nextDay(step)[start]()
            preload_range.tz[1] = pos
            tz_to_time()
            @onCurrentTime = visible_range[0] <= now < visible_range[1]

        @emitSync 'update'

      update: (view, time) =>
        unless $location.path() is '/calendar'
          @view = @type = null
          return

        return unless Prefs.hasLoaded and Pros.hasLoaded

        if typeof view is 'number'
          time = view
          view = @view
        time = @time unless time

        read_only_pro = @readOnlyProvider
        if $rootScope.hideChrome = CookiePersistence.readOnly = !!read_only_pro
          view = CALENDAR__VIEW__VERTICAL_DAY
        else
          view = update_exceptions view, time

        return if @view is view and time is @time
        time_changed = time isnt @time

        if @view isnt view
          # Click tracking
          if view is CALENDAR__VIEW__HORIZONTAL_DAY or
          view is CALENDAR__VIEW__VERTICAL_DAY
            WebTracking.track 'calendar.pageview.day',
              'num-providers': Pros.countVisible()
          else if view is CALENDAR__VIEW__WEEK
            WebTracking.track 'calendar.pageview.week'
          else if view is CALENDAR__VIEW__MONTH
            WebTracking.track 'calendar.pageview.month',
              'num-providers': Pros.countVisible()

        @view = view
        @time = time
        @tz   = timez(time * 1000) if time_changed
        @timeZone = @tz.format 'z'

        $cookieStore.put LAST_CALENDAR_VIEW, view

        @type = if view is CALENDAR__VIEW__HORIZONTAL_DAY
                  CALENDAR__VIEW__HORIZONTAL
                else if view is CALENDAR__VIEW__MONTH
                  null
                else
                  CALENDAR__VIEW__VERTICAL

        # set view defaults
        @[k] = v for k, v of defaults[@type]

        if @type is CALENDAR__VIEW__HORIZONTAL
          @gradeWidth  = @zoomDefaultGradeWidth()
        if @type is CALENDAR__VIEW__VERTICAL
          @gradeHeight = @zoomDefaultGradeHeight()

        @updateLocation()
        @providerUpdate()

        @emitSync 'core-update'
        @rangeUpdate()

      updateFromUrl: =>
        return unless Prefs.hasLoaded and $location.path() is '/calendar'

        time_from_url = ->
          format    = url_formats[view]
          tz_append = ''
          if (t = $location.search().time) and
          time = timez t + tz_append, format
            return time.unix()
          Math.floor (new Date).getTime() / 1000

        view = $location.search().view or
        $cookieStore.get(LAST_CALENDAR_VIEW) or
        default_view

        if read_only_pro = $location.search().provider
          read_only_pro = parseInt read_only_pro, 10
        @readOnlyProvider = read_only_pro

        @update view, time_from_url()

      updateLocation: =>
        @locationUpdating += 1

        if @view is default_view
          $location.search 'view', null
        else
          # view should be first
          tmp = {}
          for k, v of $location.search() when k isnt 'view'
            tmp[k] = v
            $location.search k, null
          $location.search 'view', @view
          $location.search(k, v) for k, v of tmp

        literal = @tz.format url_formats[@view]
        now     = timez().format url_formats[@view]
        $location.search 'time', if literal is now then null else literal

        setTimeout (=> @locationUpdating -= 1), 1

      updateMetrics: =>
        unless @type is CALENDAR__VIEW__HORIZONTAL
          @emSec = Prefs.increment / @gradeHeight
          @pxSec = @emSec / @emPx
          return

        path = '.calendar .slider-frame'
        if (frame = elem(path)[0])?.offsetWidth
          @visibleWidthPx = frame.offsetWidth
          @sliderWidthPx  = frame.offsetWidth * 3
          @sliderWidth    = @sliderWidthPx / @emPx
          @emSec          = Prefs.increment / @gradeWidth
          @pxSec          = @emSec / @emPx

          # time spans
          @sliderSpan  = Math.floor @sliderWidth / @gradeWidth * Prefs.increment
          @visibleSpan = Math.floor @sliderSpan / 3
          return true
        false

      # zoom level, an arbitrary number in the range specified below
      zoom: if 1 <= saved_zoom_level <= 9 then saved_zoom_level else 3
      zoomMinLevel: 1
      zoomMaxLevel: 9

      zoomIn: =>
        @zoomUpdate @zoom + 1

      zoomOut: =>
        @zoomUpdate @zoom - 1

      zoomUpdate: (level) =>
        level = Math.round level
        if @zoomMinLevel <= level <= @zoomMaxLevel and level isnt @level
          trackParams =
            'calendar-type': @view
          if level < @level
            WebTracking.track 'calendar.click.zoom-out', trackParams
          else
            WebTracking.track 'calendar.click.zoom-in', trackParams
          @zoom = level
          $cookieStore.put ZOOM_LEVEL, level
          if @type is CALENDAR__VIEW__HORIZONTAL
            @gradeWidth = @zoomDefaultGradeWidth()
          else
            @gradeHeight = @zoomDefaultGradeHeight()
          @rangeUpdate()
          @emitSync 'update'

      zoomDefaultGradeWidth: (level=@zoom) =>
        @gradeWidth = zoom_grades[level - @zoomMinLevel]
        @gradeWidth

      zoomDefaultGradeHeight: (level=@zoom) =>
        @gradeHeight = zoom_grades[level - @zoomMinLevel]

    new View
]
