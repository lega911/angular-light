
alight.filters.generator = (exp, scope, env) ->
    list = []
    watchMode: 'simple'
    onChange: (size) ->
        if list.length >= size
            list.length = size
        else
            while list.length < size
                list.push {}
        env.setValue list
