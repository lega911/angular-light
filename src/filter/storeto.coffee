
alight.filters.storeTo = (value, key, scope, env) ->
    env.changeDetector.setValue key, value
    value
