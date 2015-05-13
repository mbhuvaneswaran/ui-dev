
main.service 'CustomHolidaysMaster', [
  'List', 'CustomHoliday'
  (List, CustomHoliday) ->

    ##
    # This is a MASTER object to HolidayInstancesChild
    ##
    class CustomHolidaysMaster extends List
      api: 'CustomHoliday'
      recordClass: CustomHoliday
      sortBy: 'holidayName'

    new CustomHolidaysMaster

]
