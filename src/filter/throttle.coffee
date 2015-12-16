
alight.filters.throttle =
    init: (delay, scope) ->
        @.delay = Number delay
        @.to = null
        @.scope = scope

    onChange: (value) ->
        that = @
        if @.to
            clearTimeout @.to
        @.to = setTimeout ->
            that.to = null
            that.setValue value
            that.scope.$scan()
        , @.delay
