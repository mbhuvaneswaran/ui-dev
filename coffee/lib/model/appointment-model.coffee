
class AppointmentModel
  cloneAppointmentInstance: (appointment, createdBy) ->
    serviceLocationId:   appointment.serviceLocationId
    appointmentStatus:   appointment.appointmentStatus
    startTime:           appointment.startTime
    endTime:             appointment.endTime
    patientSummary:      appointment.patientSummary
    appointmentReasonId: appointment.appointmentReasonId
    providerId:          appointment.providerId
    resourceId:          appointment.resourceId
    notes:               appointment.notes
    resourceIds:         appointment.resourceIds
    createdBy:           createdBy
    updatedBy:           createdBy
    deleted:             appointment.deleted
    recurring:           false
    appointmentType:     appointment.appointmentType or 1

