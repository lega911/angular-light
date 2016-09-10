
alight.filters.filter = (value, text, key) ->
    if not value or not text
        return value

    result = []
    text = text.toLowerCase()
    if key
        for d in value
            s = ('' + d[key]).toLowerCase()
            if s.indexOf(text) >= 0
                result.push d
    else
        for d in value
            for k, v of d
                s = ('' + v).toLowerCase()
                if s.indexOf(text) >= 0
                    result.push d
    result
