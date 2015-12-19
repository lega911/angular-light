
alight.filters.throttle = class T
    ext: true
    constructor: (delay, scope, env) ->
        delay = Number delay
        to = null

        @.onChange = (value) ->
            if to
                clearTimeout to
            to = setTimeout ->
                to = null
                env.setValue value
                scope.$scan()
            , delay
