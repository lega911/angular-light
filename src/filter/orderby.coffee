
# | orderBy: key, reverse
alight.filters.orderBy = class O
    constructor: (exp, scope) ->
        @.list = null
        @.key = 'key'
        @.direction = 1

        d = exp.split ','

        # key
        if d[0]
            scope.$watch d[0].trim(), (value) =>
                @.key = value
                @.doSort()

        # reverse
        if d[1]
            scope.$watch d[1].trim(), (value) =>
                @.direction = if value then 1 else -1
                @.doSort()

    doSort: ->
        if @.list instanceof Array
            @.list.sort @.sortFn.bind @
            @.setValue @.list

    sortFn: (a, b) ->
        va = a[@.key] or null
        vb = b[@.key] or null
        if va < vb
            return -@.direction
        if va > vb
            return @.direction
        return 0

    onChange: (input) ->
        if input instanceof Array
            @.list = input.slice()
        else
            @.list = null
        @.doSort()
