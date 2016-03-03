
alight.utils.getId = do ->
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


alight.utils.clone = clone = (d, lvl=128) ->
    if lvl < 1
        return null

    # null, undefined
    if not d
        return d

    if typeof(d) is 'object'
        # Array
        if d instanceof Array
            r = for i in d
                clone i, lvl-1
            return r

        # Date
        if d instanceof Date
            return new Date(d.valueOf())

        # DOM?, copy link
        if d.nodeType and typeof(d.cloneNode) is "function"
            return d

        # Object
        r = {}
        for k, v of d
            if k[0] is '$'  # specific attribute
                continue
            r[k] = clone v, lvl-1
        return r
    return d


alight.utils.equal = equal = (a, b, lvl=128) ->
    if lvl < 1
        return true

    # null, undefined
    if not a or not b
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
                if not equal(v, b[i], lvl-1)
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
            if k[0] is '$'
                continue
            set[k] = true
            if not equal v, b[k], lvl-1
                return false

        for k, v of b
            if k[0] is '$'
                continue
            if set[k]
                continue
            if not equal v, a[k], lvl-1
                return false
        return true

    a is b


alight.exceptionHandler = (e, title, locals) ->
    console.warn title + '\n', (e.message || '') + '\n', locals
    err = if typeof(e) is 'string' then e else e.stack
    console.error err
