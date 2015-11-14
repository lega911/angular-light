
alight.filters.date = do ->
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

    (exp, cd) ->
        (value) ->
            makeDate exp, value
