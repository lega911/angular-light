
# | toArray:key, value
alight.filters.toArray =
    init: (scope, exp, env) ->
        if env.conf.args.length is 2
            keyName = env.conf.args[0]
            valueName = env.conf.args[1]
        else
            keyName = 'key'
            valueName = 'value'

        result = []

        watchMode: 'deep'
        onChange: (obj) ->
            result.length = 0
            for key, value of obj
                d = {}
                d[keyName] = key
                d[valueName] = value
                result.push d

            env.setValue result
