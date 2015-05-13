main.service "InsuranceService",[
  "$http"
  ($http) ->
    insuranceService = {}
    defaultUrl = "/dashboard-calendar-ui/api/Insurance"


    insuranceService.getPatientInsuranceName = (enterpriseId, patientId) ->
      $http.get(defaultUrl + "/Enterprise/" + enterpriseId + "/Patient/" + patientId + "/Company")
      
    insuranceService
]