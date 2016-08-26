
alight.filters.slice = (value, a, b) ->
    if not value
        return null
    if b
        value.slice a, b
    else
        value.slice a
