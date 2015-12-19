
alight.filters.slice = (exp, scope, env) ->
    value = null
    a = null
    b = null
    kind = null

    setter = ->
        if not value
            return
        if not kind
            return
        if kind is 2
            env.setValue value.slice a, b
        else
            env.setValue value.slice a

    d = exp.split ','
    if d.length is 1
        scope.$watch exp, (pos) ->
            kind = 1
            a = pos
            setter()
    else
        scope.$watch "#{d[0]} + '_' + #{d[1]}", (filter) ->
            kind = 2
            f = filter.split '_'
            a = Number f[0]
            b = Number f[1]
            setter()

    @.onChange = (input) ->
        value = input
        setter()
    @

alight.filters.slice::ext = true
