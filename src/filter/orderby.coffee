
# | orderBy: key, reverse
alight.filters.orderBy = (exp, cd, env) ->
    d = exp.split ','

    list = null
    key = 'key'
    direction = 1

    sortFn = (a, b) ->
        va = a[key] or null
        vb = b[key] or null
        if va < vb
            return -direction
        if va > vb
            return direction
        return 0

    doSort = ->
        if list instanceof Array
            list.sort sortFn
            env.setValue list

    # key
    if d[0]
        cd.watch d[0].trim(), (v) ->
            key = v
            doSort()

    # reverse
    if d[1]
        cd.watch d[1].trim(), (v) ->
            direction = if v then 1 else -1
            doSort()

    onChange: (input) ->
        if input instanceof Array
            list = input.slice()
        else
            list = null
        doSort()
