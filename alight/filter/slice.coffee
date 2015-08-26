
alight.filters.slice = (exp, scope, env) ->
    a = 0
    b = null
    value = null

    setter = ->
        if not value
            return
        if b
            env.setValue value.slice a, b
        else
            env.setValue value.slice a

    d = exp.split ','
    scope.$watch d[0], (v) ->
        a = v
        setter()
    ,
        init: true

    if d[1]
        scope.$watch d[1], (v) ->
            b = v
            setter()
        ,
            init: true

    onChange: (input) ->
        value = input
        setter()
