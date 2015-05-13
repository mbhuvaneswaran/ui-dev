main.service "PatientService",[
  "$http"
  ($http) ->
    patientService = {}
    defaultUrl = "/dashboard-calendar-ui/api/Patient/"


    patientService.getLastEligibilitySummary = (enterpriseId, patientId) ->
      $http.get(defaultUrl + "EnterpriseId/" + enterpriseId + "/PatientId/" + patientId + "/EligibilitySummary")


    patientService.performEligibilityCheck = (enterpriseId, patientId, providerId) ->
      $http.post(defaultUrl + "EnterpriseId/" + enterpriseId + "/PatientId/" + patientId + "/ProviderId/" + providerId + "/EligibilitySummary")

    patientService

]