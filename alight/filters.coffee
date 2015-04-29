
alight.filters.filter = (exp, scope) ->
    ce = scope.$compile exp
    (value) ->
        e = ce()
        if not e
            return value
        if typeof(e) is 'string'
            e =
                $: e
        else if typeof(e) isnt 'object'
            return value

        result = for r in value
            if typeof r is 'object'
                f = true
                if e.$
                    f = false
                    a = e.$.toLowerCase()
                    for k, v of r
                        if k is '$alite_id'
                            continue
                        if (''+v).toLowerCase().indexOf(a) >= 0
                            f = true
                            break
                    if not f
                        continue

                f = true
                for k, v of e
                    a = r[k]
                    if not a
                        continue
                    if (''+a).toLowerCase().indexOf((''+v).toLowerCase()) < 0
                        f = false
                        break
                if not f
                    continue
                r
            else
                if not e.$
                    continue
                a = e.$.toLowerCase()
                if (''+r).toLowerCase().indexOf(a) < 0
                    continue
                r

        result


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


d2 = (x) ->
    if x < 10
        return '0' + x
    '' + x

makeDate = (exp, value) ->
    if not value
        return ''

    x = [
        [/yyyy/g, value.getFullYear()]
        [/mm/g, d2 value.getMonth() + 1]
        [/dd/g, d2 value.getDate()]
        [/HH/g, d2 value.getHours()]
        [/MM/g, d2 value.getMinutes()]
        [/SS/g, d2 value.getSeconds()]
    ]
    r = exp
    for d in x
        r = r.replace d[0], d[1]
    r

alight.filters.date = (exp, scope) ->
    (value) ->
        makeDate exp, value

alight.filters.generator = (exp, scope) ->
    list = []
    (size) ->
        if list.length >= size
            list.length = size
        else
            while list.length < size
                list.push {}
        list

makeJson = (value) ->
    JSON.stringify alight.utilits.clone(value), null, 4

alight.filters.json = ->
    makeJson
