
do ->
    d2 = (x) ->
        if x < 10
            return '0' + x
        '' + x

    alight.filters.date = (value, format) ->
        if not value
            return ''

        value = new Date(value)
        
        x = [
            [/yyyy/g, value.getFullYear()]
            [/mm/g, d2 value.getMonth() + 1]
            [/dd/g, d2 value.getDate()]
            [/HH/g, d2 value.getHours()]
            [/MM/g, d2 value.getMinutes()]
            [/SS/g, d2 value.getSeconds()]
        ]
        r = format
        for d in x
            r = r.replace d[0], d[1]
        r
