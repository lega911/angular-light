
alight.filters.storeTo =
    init: (scope, key, env) ->
        onChange: (value) ->
            env.changeDetector.setValue key, value
            env.setValue value
