
CalendarCtrl.directive 'patientTypeaheadSearch', [
  '$http', '$sce', '$timeout',
  ($http, $sce, $timeout) ->
    cache = {}
    delay = 300
    delayed = null

    restrict: "A"

    link: (scope, element, attrs) ->
      node = element[0]
      selectedItem = -1
      scope.typeaheadSelectedPatient = undefined

      ##
      # Find the maximum length of our data
      ##
      findPatientDataMax = ->
        len = scope.searchedPatients.length - 1
        maxLen = scope.resultMax - 1
        if len < maxLen then len else maxLen

      angular.element(node).bind 'keydown', (event) ->
        keyCode = event.keyCode

        # only listen for certain keys
        return unless keyCode is KEYBOARD__EVENT_ENTER or
          keyCode is KEYBOARD__EVENT_DOWN_ARROW or
          keyCode is KEYBOARD__EVENT_UP_ARROW

        # enter key handling
        if keyCode is KEYBOARD__EVENT_ENTER
            scope.$apply(attrs.enterKeyFunction)
            selectedItem = -1
            scope.typeaheadSelectedPatient = undefined
            return

        # down arrow key handling
        if keyCode is KEYBOARD__EVENT_DOWN_ARROW
          if scope.searchedPatients?.length
            max = findPatientDataMax()
            if selectedItem >= max
              selectedItem = max
            else
              selectedItem += 1
            scope.typeaheadSelectedPatient =
              scope.searchedPatients[selectedItem]
          return

        # up arrow key handling
        if keyCode is KEYBOARD__EVENT_UP_ARROW
          if scope.searchedPatients?.length
            if selectedItem > 0
              selectedItem -= 1
            else
              selectedItem = 0
            scope.typeaheadSelectedPatient =
              scope.searchedPatients[selectedItem]
          return

      angular.element(node).bind 'keyup', (event) ->
        http_query = ->
          return unless scope.nameSearch?
          query = scope.nameSearch.toLowerCase()
          url = '/dashboard-calendar-ui/api/Patient/?fullName=' +
            encodeURIComponent query
          $http.get(url)
          .success (data) ->
            return unless typeof data is 'object' and data.patients

            selectedItem = -1
            scope.typeaheadSelectedPatient = undefined

            # feature note used for the moment
            #highlight = (str) ->
            #  len = query.length
            #  unless str.substr(0, len).toLowerCase() is query.toLowerCase()
            #    return str
            #  '<b>' + str.substr(0, len) + '</b>' + str.substr len

            data.patients.sort (a, b) ->
              String(a.lastName + ' ,' + a.firstName).toLowerCase() >
              String(b.lastName + ', ' + b.firstName).toLowerCase()

            now = new Date()
            for p in data.patients

              ##
              # format the name
              ##
              queried_name = p.lastName + ', ' + p.firstName
              queried_name += ' ' + p.middleName if p.middleName

              ##
              # organize the dates
              ##
              dob = new Date( p.dateOfBirth )
              dobFormatted = moment( dob ).utc().format('MM/DD/YYYY')
              age = DateConverter::getYearsOfAge(dob, now)

              ##
              # Determine the phone number
              ##
              phone = ''
              phoneLabel = ''

              ##
              # Priority order for the phone number
              ##
              if p.mobilePhone?
                phone = p.mobilePhone
                phoneLabel = 'Cell'
              else if p.homePhone?
                phone = p.homePhone
                phoneLabel = 'Home'
              else if p.workPhone?
                phone = p.workPhone
                phoneLabel = 'Work'
              else if p.otherPhone?
                phone = p.otherPhone
                phoneLabel = 'Other'

              if phoneLabel.length then phoneLabel = ', ' + phoneLabel
              if phone.length then phone = Format::SimplePhoneFormat(phone)

              ##
              # Format the result
              ##
              searchResult = "
                            <div class='grid-12 text-results'>
                              <div class='grid-12'>
                                <strong>#{queried_name}</strong> (#{age} y/o)
                              </div>
                              <div class='grid-12 small-text' ng-if='1 == 2'>
                                DOB: #{dobFormatted}#{phoneLabel}: #{phone}
                              </div>
                            </div>"

              p._queried_name = $sce.trustAsHtml searchResult

            cache[query] = data.patients

            if scope.nameSearch and query is scope.nameSearch.toLowerCase()
              scope.searchedPatients = cache[query]
              scope.searching = false

          .error ->
            scope.searching = false
            scope.searchError = true

        if scope.nameSearch
          query = scope.nameSearch.toLowerCase()

        if query and query.length > 1
          if cache[query]?
            return scope.searchedPatients = cache[query]

          scope.searching = true
          scope.searchError = false
          scope.searchedPatients = []
          unless delayed
            delayed = $timeout ->
              delayed = null
              http_query()
            , delay
        else
          scope.searching = false
]
