
alight.filters.throttle =
    init: (scope, delay, env) ->
        delay = Number delay
        to = null

        onChange: (value) ->
            if to
                clearTimeout to
            to = setTimeout ->
                to = null
                env.setValue value
                env.changeDetector.scan()
            , delay
