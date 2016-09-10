
alight.filters.json =
    init: (scope, expression, env) ->
        watchMode: 'deep'
        onChange: (value) ->
            env.setValue JSON.stringify alight.utils.clone(value), null, 4
