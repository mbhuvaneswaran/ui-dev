
CalendarCtrl.factory 'CanvasPosition', [
  'EventEmitter', 'Prefs', 'Pros', 'Resources', 'timez',
  (EventEmitter, Prefs, Pros, Resources, timez) ->

    COLUMN_RIGHT_SPACING = 1.5 # percent of canvas width

    class CanvasPosition extends EventEmitter
      colWidth: (number_only) =>
        n = Math.floor(100000 / @columns().length) / 1000
        return n if number_only
        n + '%'

      apptPos: (appt, type_flag) =>
        em_px  = @emPx
        px_sec = @pxSec
        data   = appt.data
        start  = (data.startTime or data.startDateTime) / 1000
        end    = (data.endTime or data.endDateTime) / 1000
        len    = end - start
        if data.providerId
          pro = Pros.get data.providerId
        else
          pro = Resources.get data.resourceId

        switch @type
          when CALENDAR__VIEW__HORIZONTAL
            switch type_flag
              when CALENDAR__POS__FULL_COVER
                h = pro.height - 2
                t = pro.top - 1
              when CALENDAR__POS__PSEUDO # placeholder
                t = appt.pseudoTop
                h = Math.min 2 * em_px, pro.pxBottom - t - 3
              when CALENDAR__POS__TIMELINE
                bottom = '1px'
                _w = '1px'
                t  = 2 * em_px
              else # standard appt
                h = (if appt.levels then @apptMinHeight - .1 else @apptHeight) *
                    em_px
                t = pro.top - 1 + Math.round appt.level * @apptMinHeight * em_px

            bottom: bottom
            height: if bottom then null else (h + 'px')
            left:   Math.round((start - @range.render[0]) / px_sec + 2) + 'px'
            top:    (t + 1) + 'px'
            width:  _w or (Math.round((len / px_sec) - 3) + 'px')

          else # VERTICAL
            col_width  = @colWidth true
            start_tz   = (appt.startTime?()) or timez start * 1000
            sec_of_day = start_tz.secOfDay()
            push  = 0

            top = Math.floor(sec_of_day / px_sec + 1 + 2 * em_px) + 'px'

            visible_id = pro?.visibleId
            if @view is CALENDAR__VIEW__WEEK
              unless (day = appt.day)?
                if data.dayOfWeek? # office-hrs
                  day = @days[(data.dayOfWeek + 6) % 7]
                else # time-off
                  day = @days[(appt.startTime().day() + 6) % 7]
              return {top, display: 'none'} unless day?.visible
              visible_id = day.visibleId

            left  = col_width * visible_id + .1
            width = col_width

            switch type_flag
              when CALENDAR__POS__FULL_COVER
                _z = 1
              when CALENDAR__POS__PSEUDO # placeholder
                width = col_width - COLUMN_RIGHT_SPACING
                if appt.pushed
                  left += col_width - COLUMN_RIGHT_SPACING
                  width = COLUMN_RIGHT_SPACING
              when CALENDAR__POS__TIMELINE
                _h = '1px'
              else # standard appt
                width = (col_width - COLUMN_RIGHT_SPACING) / (appt.levels + 1)
                left  += appt.level * width

            height: _h or (Math.floor(len / px_sec - 1) + 'px')
            left:   left + '%'
            top:    top
            width:  width + '%'

      nextDayTzFor: (tz) ->
        day_n = tz.format 'YYYYMMDD'
        idx = CACHE_PREFIX + 'nextDayStartTz_' + @timeZone
        @[idx] ?= {}
        unless @[idx][day_n]
          timez()
          @[idx][day_n] = tz.nextDay().startOfDay()
        @[idx][day_n]

      daySlice: (appt) ->
        copy_propertries = (from, to) ->
          for own key, value of from
            if to[key] is undefined and not (key.substr(0, 2) in ['$$', '__'])
              to[key] = value
          return

        ymd = (tz) ->
          Number tz.format 'YYYYMMDD'

        end_literal   = 'endTime'
        start_literal = 'startTime'
        if appt.saved.startDateTime?
          end_literal   = 'endDateTime'
          start_literal = 'startDateTime'

        start = appt.startTime()
        end   = appt.endTime()

        if ymd(start) is end_ymd = ymd end
          return [appt]

        class_ref = appt.constructor

        pos = @nextDayTzFor start

        inf = appt.copyData()
        inf[end_literal] = pos.valueOf()
        slices = [new class_ref inf]

        until end_ymd is ymd pos
          inf = appt.copyData()
          inf[start_literal] = pos.valueOf()
          pos = @nextDayTzFor pos
          inf[end_literal] = pos.valueOf()
          slices.push new class_ref inf

        inf = appt.copyData()
        inf[start_literal] = pos.valueOf()
        slices.push new class_ref inf

        for slice, i in slices
          copy_propertries appt, slice
          slice._origAppt = appt
          slice.tornEnd   = i < slices.length - 1
          slice.tornStart = i > 0

        for slice, i in slices
          slice.daySliceId = i

        slices

      posInfo: (x, y) =>
        increment     = Prefs.increment
        visible_range = @range.visible
        {top, left} = page_offset '.calendar .slider'

        vertical_info = =>
          columns = @columns()
          width   = elem('.calendar .slider .columns')[0].offsetWidth
          col_w   = width / columns.length
          x      -= left + 4 * @emPx

          colId:   Math.floor x / col_w
          columns: columns
          y:       y - top - 2 * @emPx + elem('.calendar .slider')[0].scrollTop

        switch @view
          when CALENDAR__VIEW__HORIZONTAL_DAY
            closest = -10000
            for target in Pros.withResources() when target.visible
              pro_y = target.top
              if closest < pro_y < y - top
                closest = pro_y
                pro = target

            t = timez (visible_range[0] + (x - left) * @pxSec) * 1000
            sec = t.unix() - t.secOfDay() % increment

          when CALENDAR__VIEW__VERTICAL_DAY
            {colId, columns, y} = vertical_info()
            unless pro = columns[colId]
              return {sec: null, pro: null}
            sec = visible_range[0] + y * @pxSec
            sec -= (sec - visible_range[0]) % increment

          else # CALENDAR__VIEW__WEEK
            pro = Pros.parseXid(Pros.selectedProviderId).record
            {colId, columns, y} = vertical_info()
            unless (day = columns[colId]) and day.tz
              return {sec: null, pro: null}
            sec = Math.floor day.tz.unix() + y * @pxSec
            sec -= (sec - day.tz.unix()) % increment

        {sec, pro}
]
