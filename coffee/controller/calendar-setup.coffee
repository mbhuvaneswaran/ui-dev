
CalendarSetupCtrl = main.controller 'CalendarSetupCtrl', [
  '$scope', '$http', '$timeout', '$routeParams', '$location',
  'authenticatedUser', 'FeatureToggle', 'Modal', 'UrlFor'
  ($scope, $http, $timeout, $routeParams, $location,
   authenticatedUser, FeatureToggle, Modal, UrlFor) ->

    authenticatedUser.get().then ->
      authorized = authenticatedUser.hasPrivilegeAccess(AUTH__CALENDAR_SETUP,
        AUTH__WRITE)
      if not authorized
        $location.path('/dashboard')

    defaultContainerClass = "grid-12"

    $scope.durationUnits = "minutes"
    $scope.durationUnitsPrefix = "min"

    $scope.Modal = Modal

    # default initializers
    $scope.formData = {}
    $scope.data = {}
    $scope.editor = {}

    $scope.urlFor = UrlFor
    $scope.mainContainerClass = defaultContainerClass

    FeatureToggle.if 'load', ->
      $scope.nonProviderFeaturesToggled =
        FeatureToggle.enabled[FT_DARK_NON_PROVIDER_CALENDARS]

    ########################################################
    ## CURRENT VIEW LOGIC
    ########################################################
    if $routeParams.view
      $scope.view = $routeParams.view
    else
      $scope.view = 'general'

    $scope.changeView = (view) ->
      if view != $scope.view
        $scope.closeEditor()

        $location.search('view', view)

        $scope.view = view

    ########################################################
    ## CONFIRM DELETE UI LOGIC
    ########################################################
    $scope.confirmDelete = (formData) ->
      $scope.confirmRemove = true
      formData.submission = 'delete'

    $scope.cancelDelete = (formData) ->
      $scope.confirmRemove = false
      formData.submission = 'update'

    ########################################################
    ## EDITOR/DELETOR UI LOGIC
    ########################################################
    $scope.openEditor = (card) ->
      $scope.deletorShow = false
      $scope.editorCard = card

      Modal.open( card.modal )

      $scope.editorShow = true if !$scope.editorShow

    $scope.closeEditor = (form) ->
      $scope.editorShow = false
      $scope.formData.id = null
      $scope.editorCard = null
      $scope.confirmRemove = false

      Modal.close()
      
      form.$setPristine() if form

    $scope.resetForm = ->
      $scope.formData = {}

    #########################################
    # CONFIGURATION
    #########################################

    # Each card item represents a different section of the calendar setup
    $scope.cardItems = {
      visitReason : {
        type: 'reason',
        title: "Visit Reasons",
        button: "New Visit Reason",
        reference: 'new-reason-btn',
        modal: 'visitReasonModal'
      },

      room : {
        type: 'room',
        title: 'Rooms',
        button: 'New Room',
        reference: 'new-staff-room-btn',
        modal: 'resourceModal'
      },

      equipment : {
        type: 'equipment',
        title: 'Equipment',
        button: 'New Equipment',
        reference: 'new-equipment-room-btn',
        modal: 'resourceModal'
      }
    }
]