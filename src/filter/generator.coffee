
alight.filters.generator = class G
    watchMode: 'simple'
    constructor: (key, scope, env) ->
        list = []
        @.onChange = (size) ->
            if list.length >= size
                list.length = size
            else
                while list.length < size
                    list.push {}
            env.setValue list
