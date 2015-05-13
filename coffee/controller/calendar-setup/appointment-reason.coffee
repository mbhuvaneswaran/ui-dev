CalendarSetupAppointmentReasonCtrl =
CalendarSetupCtrl.controller 'CalendarSetupAppointmentReasonCtrl', [
  '$scope', '$http', '$timeout', '$routeParams',
  'AppointmentReasonRepository', 'ApptReasons', 'LoggerFactory'
  ($scope, $http, $timeout, $routeParams,
    AppointmentReasonRepository, ApptReasons, LoggerFactory) ->

      # Reference
      # $scope.appId

      if $scope.data.appointmentReasons is undefined
        $scope.data.appointmentReasons = []

      $scope.colorpalette = ColorPaletteModel::getColorPalette()
      $scope.defaultColor = $scope.colorpalette[0]

      logger = LoggerFactory.getLogger(enabled=false, "AppointmentReasonCtrl")

      #############################################################
      ## SHARED DATA INTEGRATION HOOKS
      #############################################################
      integrationHookUpsertApptReason = ( appt_reason_data ) ->
        id = appt_reason_data.appointmentReasonId
        logger.trace( 'integrationHookUpsertApptReason', "id:#{id}" )
        ApptReasons.upsert( appt_reason_data ) if ApptReasons.data?.length >= 0
        ApptReasons.sort( 'name' )

      integrationHookCutApptReason = ( appt_reason_id ) ->
        logger.trace( 'integrationHookCutApptReason', "id:#{appt_reason_id}" )
        appt_reason = ApptReasons.get appt_reason_id
        ApptReasons.cut( appt_reason ) if appt_reason
        ApptReasons.sort( 'name' )

      #############################################################
      ## FORM SUBMISSIONS
      #############################################################
      $scope.submit = (card, formData, form) ->
        $scope.formData.inputError = true if form.$invalid

        response_handler = ->
          form.submitted = false

        form.submitted = true
        if form.$valid and card.type is 'reason'
          form.$setPristine()

          form.submitted = true
          if formData.submission is "update"
            $scope.updateAppointmentReason formData, response_handler
          else if formData.submission is "delete"
            $scope.removeAppointmentReason formData, response_handler
          else
            $scope.createAppointmentReason formData, response_handler

      #############################################################
      ## COLOR PALETTE HANDLERS
      #############################################################
      $scope.colorStyle = (color) ->
        {
          'background-color' : color
        }

      $scope.showColorPalette = () ->
        $scope.colorPaletteOpen = true

      $scope.hideColorPalette = (delay) ->
        $timeout(->
          $scope.colorPaletteOpen = false
        , delay || 0)

      $scope.toggleColorPalette = () ->
        if $scope.isColorPaletteOpen()
          $scope.hideColorPalette()
        else
          $scope.showColorPalette()

      $scope.isColorPaletteOpen = () ->
        !!$scope.colorPaletteOpen

      $scope.setColor = (color) ->
        $scope.formData.colorpicker = color

      #############################################################
      ## CLICK HANDLERS
      #############################################################
      $scope.showCreateAppointmentReason = (card) ->
        $scope.resetForm()
        $scope.formData.submission = "create"
        $scope.formData.colorpicker = $scope.defaultColor

        $scope.editor.title = "New Visit Reason"
        $scope.openEditor(card)

      $scope.showEditAppointmentReason = (card, appointmentReason) ->
        $scope.resetForm()
        $scope.formData.submission = "update"
        $scope.formData.name = appointmentReason.name
        $scope.formData.id = appointmentReason.appointmentReasonId
        $scope.formData.colorpicker = appointmentReason.hexColor
        $scope.formData.duration = appointmentReason.duration

        $scope.editor.title = "Edit Visit Reason"
        $scope.openEditor(card)

      #############################################################
      ## HTTP HANDLERS
      #############################################################
      $scope.getAppointmentReasons = () ->
        AppointmentReasonRepository.getAllAppointmentReasons()
        .success((data) ->
          for entry in data
            unless entry.deleted
              rgb = HexRGBConverter::numToRGB(entry.rgbColor)
              entry.hexColor = HexRGBConverter::convertHexFromRGB(
                rgb[0], rgb[1], rgb[2])

              $scope.data.appointmentReasons.push entry
        )
        .error( (data) ->
          $scope.formData.submissionError = ErrorHandler.getStatus(data, status)
        )

      $scope.createAppointmentReason = (formData, callback) ->
        integerColor =
          getIntegerColor(formData.colorpicker,$scope.defaultColor)
        hexColor = formData.colorpicker

        AppointmentReasonRepository.createAppointmentReason({
          name: formData.name,
          duration: formData.duration,
          rgbColor: integerColor
        })
        .success( (data) ->
          data.hexColor = hexColor
          $scope.data.appointmentReasons.push(data)
          $scope.closeEditor()

          integrationHookUpsertApptReason( data )
          callback? null, data
        )
        .error( (data, status) ->
          $scope.formData.submissionError = ErrorHandler.getStatus(data, status)
          callback? status, data
        )

      $scope.updateAppointmentReason = (formData, callback) ->
        appointmentReason = null

        for entry in $scope.data.appointmentReasons
          if entry.appointmentReasonId is formData.id
            appointmentReason = entry

        integerColor = getIntegerColor(
          formData.colorpicker, $scope.defaultColor)
        hexColor = formData.colorpicker

        $scope.cache_save = angular.copy(appointmentReason)

        appointmentReason.name = formData.name
        appointmentReason.duration = formData.duration
        appointmentReason.hexColor = hexColor
        appointmentReason.integerColor = integerColor

        AppointmentReasonRepository.updateAppointmentReason({
          name: appointmentReason.name,
          duration: appointmentReason.duration,
          rgbColor: appointmentReason.integerColor,
        }, appointmentReason.appointmentReasonId)
        .success((data) ->
          $scope.closeEditor()
          integrationHookUpsertApptReason( data )
          callback? null, data
        )
        .error((data, status) ->
          $scope.formData.submissionError = ErrorHandler.getStatus(data, status)

          appointmentReason.name = $scope.cache_save.name
          appointmentReason.duration = $scope.cache_save.duration
          appointmentReason.hexColor = $scope.cache_save.hexColor
          callback? status, data
        )

      $scope.removeAppointmentReason = (formData, callback) ->
        AppointmentReasonRepository.removeAppointmentReason(formData.id)
        .success( (data) ->
          $scope.data.appointmentReasons =
            $scope.data.appointmentReasons.filter (entry) ->
              entry.appointmentReasonId isnt formData.id
          $scope.closeEditor()

          integrationHookCutApptReason( formData.id )
          callback? null, data
        )
        .error( (data, status) ->
          $scope.formData.submissionError =
            ErrorHandler.getStatus(data, status)
          callback? status, data
        )

      getIntegerColor = (hexColor, defaultColor) ->
        if hexColor is null or hexColor is undefined
          hexColor = defaultColor

        rgb = HexRGBConverter::convertRGBFromHex(hexColor)
        return HexRGBConverter::RGBToNum(rgb[0], rgb[1], rgb[2])

      if not $scope.data.appointmentReasonsLoaded?
          $scope.data.appointmentReasonsLoaded = true
          $scope.getAppointmentReasons()
  ]