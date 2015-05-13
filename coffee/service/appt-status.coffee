
CalendarCtrl.service 'ApptStatus', ->
  statuses = ['unknown',          # 0
              'scheduled',        # 1
              'reminder-sent',    # 2
              'confirmed',        # 3
              'checked-in',       # 4
              'roomed',           # 5
              'checked-out',      # 6
              'needs-reschedule', # 7
              'ready-to-be-seen', # 8
              'no-show',          # 9
              'cancelled',        # 10
              'rescheduled',      # 11
              'tentative']        # 12


  statuses.camel = (Strings::dashToCamel(status) for status in statuses)

  statuses.fancyDisplay = (Strings::dashToSpace(status) for status in statuses)

  statuses.groups =
    inOffice:  [8, 4, 5] # ready-to-be-seen, checked-in, roomed
    scheduled: [1, 3, 5] # scheduled, confirmed, reminder-sent
    cancelled: [10, 9] # cancelled, no-show
    completed: [6, 10, 9] # checked-out, cancel'd, no-show
    rescheduled: [11] # rescheduled
    tentative: [12] # tentative

  statuses.getGroup = (status_id) ->
    for group, values of statuses.groups
      return group if Number(status_id) in values
    false

  statuses.id = (status_name) ->
    for status, index in statuses
      return index if status is status_name

  statuses
