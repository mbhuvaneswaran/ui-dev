
app = angular.module 'app', ['ngAnimate', 'ngCookies', 'ngRoute', 'ngTouch',
                             'ksc',
                             'kareo.ui.shared.directives.content-height',
                             'kareo.ui.shared.directives.analytics',
                             'kareo.ui.shared.directives.dropdown',
                             'kareo.ui.shared.directives.patient-create',
                             'kareo.ui.shared.directives.chrome-header',
                             'kareo.ui.shared.directives.outstanding-items',
                             'kareo.ui.shared.directives.templates',
                             'kareo.ui.shared.directives.tour-card',
                             'kareo.ui.shared.modules.featureSet',
                             'kareo.ui.shared.modules.idleMonitor',
                             'kareo.ui.shared.modules.intercom',
                             'kareo.ui.shared.modules.data-filters',
                             'kareo.ui.tour',
                             'main',
                             'app-config',
                             'kareo.default-configuration']

app.config ['$routeProvider', ($routeProvider) ->
  calendar =
    controller: 'CalendarCtrl'
    templateUrl: 'partials/calendar.html'
    reloadOnSearch: false

  calendarSetup =
    controller: 'CalendarSetupCtrl'
    templateUrl: 'partials/calendar-setup.html'

  officeHoursSetup =
    controller: 'CalendarSetupOfficeHoursCtrl'
    templateUrl: 'partials/calendar-setup/office-hours-setup.html'

  frontdeskDashboard =
    controller: 'FrontdeskDashboardCtrl'
    templateUrl: 'partials/frontdesk-dashboard.html'
    reloadOnSearch: false

  $routeProvider
  .when('/calendar', calendar)
  .when('/calendar-setup/office-hours-setup/:id/:type/:name', officeHoursSetup)
  .when('/calendar-setup', calendarSetup)
  .when('/dashboard', frontdeskDashboard)
  .otherwise redirectTo: '/dashboard'

]

app.config ['$httpProvider', ($httpProvider) ->

  # IE 11 cache fix
  headers_get = $httpProvider.defaults.headers.get ?= {}
  headers_get['Cache-Control'] = 'no-cache'
  headers_get.Pragma = 'no-cache'
]

main = angular.module 'main', ['api']

angular.module 'app-config', []