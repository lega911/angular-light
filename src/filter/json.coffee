
alight.filters.json = do ->
    makeJson = (value) ->
        JSON.stringify alight.utils.clone(value), null, 4

    (exp, cd, env) ->
        watchMode: 'deep'
        onChange: (value) ->
            env.setValue makeJson value
