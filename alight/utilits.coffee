
alight.utilits.getId = do ->
    prefix = do ->
        symbols = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.split ''
        n = Math.floor((new Date()).valueOf() / 1000) - 1388512800
        r = ''
        while n > 0
            d = Math.floor n / 62
            p = d * 62
            k = n - p
            n = d
            r = symbols[k] + r
        r

    index = 1;
    return ->
        return prefix + '#' + index++


alight.utilits.filterBuilder = (scope, func, line) ->
    if not line or not line.length
        return func
    for f in line
        d = f.match(/\s*([\w\d_]+?)\s*:\s*(.*?)\s*$/)
        if d
            fname = d[1]
            param = d[2]
        else
            fname = f.trim()
            param = null

        fbase = alight.getFilter fname, scope, param
        filter = fbase.call scope, param, scope

        if func
            func = do (fl = filter, fn = func) ->
                (value) ->
                    fl fn value
        else
            func = filter
    func


alight.utilits.clone = clone = (d) ->
    # null, undefined
    if not d
        return d

    if typeof(d) is 'object'
        # Array
        if d instanceof Array
            r = for i in d
                clone i
            return r

        # Date
        if d instanceof Date
            return new Date(d)

        # DOM?, copy link
        if d.nodeType and typeof(d.cloneNode) is "function"
            return d

        # Object
        r = {}
        for k, v of d
            if k is '$alite_id'  # specific attribute
                continue
            r[k] = clone v
        return r
    return d


alight.utilits.equal = equal = (a, b) ->
    # null, undefined
    if not a
        return a is b

    ta = typeof a
    tb = typeof b
    if ta isnt tb
        return false
    if ta is 'object'
        # Array
        if a instanceof Array
            if a.length isnt b.length
                return false
            for v, i in a
                if not equal(v, b[i])
                    return false
            return true

        # Date
        if a instanceof Date
            return a.valueOf() is b.valueOf()

        # DOM?, copy link
        if a.nodeType and typeof(a.cloneNode) is "function"
            return a is b

        # Object
        set = {}
        for k, v of a
            if k is '$alite_id'
                continue
            set[k] = true
            if not equal v, b[k]
                return false

        for k, v of b
            if k is '$alite_id'
                continue
            if set[k]
                continue
            if not equal v, a[k]
                return false
        return true

    a is b


alight.utilits.dataByElement = (el, key) ->
    al = el.al
    if not al
        el.al = al = {}
    if key
        if not al[key]
            al[key] = {}
        return al[key]
    return al


alight.exceptionHandler = (e, title, locals) ->
    console.warn title, locals
    err = if typeof(e) is 'string' then e else e.stack
    console.error err
