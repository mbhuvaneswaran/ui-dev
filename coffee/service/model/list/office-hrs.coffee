
main.service 'OfficeHrs', [
  '$http', 'List', 'OfficeHr', 'UrlFor',
  ($http, List, OfficeHr, UrlFor) ->
    class OfficeHrs extends List
      api: 'OfficeHrs'
      recordClass: OfficeHr
      sortBy:
        property: ['startTime', 'endTime', 'officeHrsId']
        type: 'number'

      groupByDay: (officeHoursList) ->
        group = {}

        for item in officeHoursList
          group[item.data.dayOfWeek] = [] unless group[item.data.dayOfWeek]?
          group[item.data.dayOfWeek].push item

        group

      saveAll: (payload, callback) ->
        url = UrlFor.api('OfficeHr') + 'upsert'
        upd = $http.post url, payload
        upd.success (data) ->
          callback?( data )
        upd.error ->
          console.error? 'error', arguments
          alert 'Failed to save'

    new OfficeHrs
]
