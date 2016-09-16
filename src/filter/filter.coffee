
alight.filters.filter = (input, _a, _b) ->
    if arguments.length is 2
        key = null
        value = _a
    else if arguments.length is 3
        key = _a
        value = _b
    else
        return input
    if not input or not value? or value is ''
        return input

    result = []
    svalue = ('' + value).toLowerCase()
    if key
        for d in input
            if d[key] is value
                result.push d
            else
                s = ('' + d[key]).toLowerCase()
                if s.indexOf(svalue) >= 0
                    result.push d
    else
        for d in input
            for k, v of d
                if v is value
                    result.push d
                else
                    s = ('' + v).toLowerCase()
                    if s.indexOf(svalue) >= 0
                        result.push d
    result
