
alight.filters.throttle = (delay, cd, env) ->
    delay = Number delay
    to = null

    onChange: (value) ->
        if to
            clearTimeout to
        to = setTimeout ->
            to = null
            env.setValue value
            cd.scan()
        , delay
