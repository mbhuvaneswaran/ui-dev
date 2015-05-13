
CalendarCtrl.service 'Pros', [
  '$cookieStore', 'FeatureToggle', 'List', 'Pro', 'Resources',
  ($cookieStore, FeatureToggle, List, Pro, Resources) ->

    SELECTED_PRO_KEY = 'selectedProviderId'


    class Pros extends List
      api:         'Pros'
      recordClass: Pro
      sortBy:      method: 'name'

      constructor: ->
        super
        @if1 'load', =>
          if (cookie = $cookieStore.get SELECTED_PRO_KEY)?
            xid = @parseXid String cookie
            unless @[SELECTED_PRO_KEY] = xid.type + xid.id
              $cookieStore.remove SELECTED_PRO_KEY

      countVisible: (provider_only) =>
        count = 0
        count += 1 for pro in @data when pro.visible
        if not provider_only and
        FeatureToggle.enabled[FT_DARK_NON_PROVIDER_CALENDARS]
          count += 1 for rsc in Resources.data when rsc.visible
        count

      updateSelected: =>
        if (selection = @[SELECTED_PRO_KEY])?
          $cookieStore.put SELECTED_PRO_KEY, selection
          @emitSync 'update'

      withResources: (types...) =>
        if types.length is 0
          types = [0, 2, 3] # 0 is casted as provider, others ref resourceTypeId
          # resource type 1 is room, it is excluded by default

        list = if 0 in types then (item for item in @data) else []
        if FeatureToggle.enabled[FT_DARK_NON_PROVIDER_CALENDARS]
          for item in Resources.data when item.data.resourceTypeId in types
            list.push item

        # sort order is:
        #   1) providers and staff mixed by name
        #   2) equipments
        #   3) rooms
        list.sort (a, b) ->
          arb_order = (record) ->
            [0, 3, 2, 1][record.data.resourceTypeId or 0]

          if arb_order(a) > arb_order(b)
            return 1
          if arb_order(a) < arb_order(b)
            return -1

          if a.name() > b.name()
            return 1
          -1

        list

      parseXid: (xid) =>
        xid = String xid

        res =
          id: Number xid.substr 3
          providerId: null
          resourceId: null
          type: xid.substr 0, 3

        if xid.substr(0, 3) is 'rsc'
          res.target = Resources
          res.resourceId = res.id
        else if xid.substr(0, 3) is 'pro'
          res.target = @
          res.providerId = res.id

        if res.target
          res.record = res.target.get res.id

        res


    new Pros
]
