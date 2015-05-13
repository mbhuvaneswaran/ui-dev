# The AppointmentState Controller handles transitioning appointments between
# each state. It's also responsible for handling the patient dropdown
# at this time, however that will likely change as the dropdown gets built

PatientLoadCtrl = FrontdeskDashboardCtrl.controller 'PatientLoadCtrl', [
  '$scope', '$filter', ($scope, $filter)->

    providerTotals = {}

    $scope.getProviderLoad = (appointments, provider, serviceLocation) ->
      list = $filter('providerLoadFilter')(
        appointments, provider, serviceLocation)

      providerTotals[provider.providerId] = list.length

      list

    $scope.getTotalLoad = ->
      total = 0
      for key, val of providerTotals
        total += val

      total

    $scope.getLocationLoad = (appointments, serviceLocation) ->
      $filter('serviceLocationFilter')(appointments, serviceLocation)
]
