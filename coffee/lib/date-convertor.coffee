NOON_SECONDS = 12 * 60 * 60 * 1000
MS_IN_MINUTE = 60 * 1000
MS_IN_HOUR = 60 * MS_IN_MINUTE

MINUTES_15_MS = 15 * MS_IN_MINUTE
MINUTES_30_MS = 30 * MS_IN_MINUTE
MINUTES_45_MS = 45 * MS_IN_MINUTE
MINUTES_60_MS = 60 * MS_IN_MINUTE
MINUTES_90_MS = 90 * MS_IN_MINUTE

NEXT_DAY = ' (next day)'

class DateConverter

  # [12:00am, 12:15am, .. 11:45pm], given step of 15
  getTimeSlots: (step_minutes, include_midnight) ->
    end = 24 * 60
    if include_midnight
      end += .1

    for mark in [0 ... end] by step_minutes
      hour      = mark // 60
      minute    = mark % 60
      extra_day = hour // 24
      hour      = hour % 24
      minute = '0' + minute if String(minute).length is 1
      meridian = if 12 <= hour then 'pm' else 'am'
      hour = hour % 12
      hour = 12 unless hour

      extra_day = if extra_day then NEXT_DAY else ''

      hour + ':' + minute + meridian + extra_day

  # 12:25 pm
  getShortTime: (dateObj) ->
    timeParts = DateConverter::getTimeParts(dateObj)

    "#{timeParts.hours}:#{timeParts.minutes}#{timeParts.meridian.toLowerCase()}"

  getShortTimeDifference: (millis) ->
    timeDifferenceParts = DateConverter::getTimeDifferenceParts(millis)

    if timeDifferenceParts.hours != 0
      if timeDifferenceParts.hours is 1
        return "#{timeDifferenceParts.hours}+ hr"
      return "#{timeDifferenceParts.hours}+ hrs"

    else if timeDifferenceParts.minutes != 0
      if timeDifferenceParts.minutes is 1
        return "#{timeDifferenceParts.minutes} min"
      return "#{timeDifferenceParts.minutes} mins"

      # else if timeDifferenceParts.seconds != 0
      #   if timeDifferenceParts.seconds is 1
      #     return "#{timeDifferenceParts.seconds} sec"
      #   return "#{timeDifferenceParts.seconds} secs"

    else return "0 mins"

  getYearsOfAge: (dob, now) ->
    now = new Date() if not now

    years = now.getYear() - dob.getYear()

    if ( now.getMonth() < dob.getMonth() ) or
    ( now.getMonth() == dob.getMonth() and now.getDate() < dob.getDate() )
      years--

    years

  # {hours:hours, minutes:minutes, seconds:seconds}
  getTimeDifferenceParts: (millis) ->
    secondsToHoursConversion = 3600
    secondsToMinutesConversion = 60

    remainingSeconds = parseInt(millis / 1000)
    hours = minutes = seconds = null

    if remainingSeconds >= secondsToHoursConversion
      hours = parseInt(remainingSeconds / secondsToHoursConversion)
      remainingSeconds = remainingSeconds - hours * secondsToHoursConversion

    if remainingSeconds >= secondsToMinutesConversion
      minutes = parseInt(remainingSeconds / secondsToMinutesConversion)
      remainingSeconds = remainingSeconds - minutes * secondsToMinutesConversion

    if remainingSeconds > 0
      seconds = remainingSeconds

    {
    hours: hours || 0
    minutes: minutes || 0
    seconds: seconds || 0
    }

  # {hours:hours, minutes:minutes, seconds:seconds, meridian:meridian}
  getTimeParts: (dateObj) ->
    is_am = true
    hours = null
    clockConversion = 12
    if dateObj.getHours() >= clockConversion
      hours = dateObj.getHours() - clockConversion
      is_am = false
    else
      hours = dateObj.getHours()

    hours = 12 if hours is 0

    seconds = "" + dateObj.getSeconds()
    seconds = "0#{seconds}" if seconds.length == 1

    minutes = "" + dateObj.getMinutes()
    minutes = "0#{minutes}" if minutes.length == 1

    {
    hours: hours,
    minutes: minutes,
    seconds: seconds,
    meridian: if is_am == true then 'AM' else 'PM'
    }

  parseMsInDay: (timeString) ->
    return unless timeString?

    extra_day = 0
    if (pos = timeString.indexOf NEXT_DAY) > -1
      extra_day  = DAY_IN_MS
      timeString = timeString.substr 0, pos

    parts = timeString.split(':') #split into Hour and MinutesPeriod
    return unless parts?.length is 2 and parts[1]?.length is 4

    hourSeconds = if parts[0] is '12' then 0 else parts[0] * MS_IN_HOUR
    hourSeconds += NOON_SECONDS unless parts[1].substring(2) is 'am'
    minuteSeconds = parts[1].substring(0, 2) * MS_IN_MINUTE
    hourSeconds + minuteSeconds + extra_day

  formatTimeOfDayFromMS: (ms) ->
    extra_day = ms // DAY_IN_MS

    hours = Math.floor(ms / MS_IN_HOUR) % 24
    minutes = Math.round(((ms % MS_IN_HOUR) / MS_IN_HOUR) * 60)
    period = 'am'
    if hours >= 12
      period = 'pm'
      if hours > 12
        hours -= 12
    else
      hours = 12 if hours is 0

    extra_day = if extra_day then NEXT_DAY else ''

    hours + ':' + Strings::leftPad('0', minutes, 2) + period + extra_day

  parseDurMS: (durationString) ->
    switch durationString
      when '15min' then MINUTES_15_MS
      when '30min' then MINUTES_30_MS
      when '45min' then MINUTES_45_MS
      when '1hr' then MINUTES_60_MS
      when '1.5hr' then MINUTES_90_MS

  formatDurationFromMinutes: (minutes) ->
    switch minutes
      when 15 then '15min'
      when 30 then '30min'
      when 45 then '45min'
      when 60 then '1hr'
      when 90 then '1.5hr'

  parsePickerFormat: (pickerValue, format) ->
    return unless pickerValue
    unless format
      parts = pickerValue.split("/")
      return  unless parts
      new Date(parts[2], parts[0] - 1, parts[1])
    else
      momentObj = moment(pickerValue, format)
      new Date(momentObj.toString())