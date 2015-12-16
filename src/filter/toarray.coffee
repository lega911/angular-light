
# | toArray:key, value
alight.filters.toArray =
    watchMode: 'deep'
    init: (exp, scope) ->
        if exp
            d = exp.split ','
            if d.length is 2
                @.keyName = d[0].trim()
                @.valueName = d[1].trim()
            else
                throw 'Wrong filter arguments for toArray'
        else
            @.keyName = 'key'
            @.valueName = 'value'

        @.result = []

    onChange: (obj) ->
        @.result.length = 0
        for key, value of obj
            d = {}
            d[@.keyName] = key
            d[@.valueName] = value
            @.result.push d

        @.setValue @.result
