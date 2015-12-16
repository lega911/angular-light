
alight.filters.slice =
    init: (exp, scope) ->
        that = @
        that.value = null
        a = null
        b = null
        kind = null

        that.setter = ->
            if not that.value
                return
            if not kind
                return
            if kind is 2
                that.setValue that.value.slice a, b
            else
                that.setValue that.value.slice a

        d = exp.split ','
        if d.length is 1
            scope.$watch exp, (pos) ->
                kind = 1
                a = pos
                that.setter()
        else
            scope.$watch "#{d[0]} + '_' + #{d[1]}", (filter) ->
                kind = 2
                f = filter.split '_'
                a = Number f[0]
                b = Number f[1]
                that.setter()

    onChange: (input) ->
        @.value = input
        @.setter()
