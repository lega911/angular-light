
# | orderBy key reverse
alight.filters.orderBy = (value, key, reverse) ->
    if not value instanceof Array
        return null

    if reverse
        reverse = 1
    else
        reverse = -1

    value.sort (a, b) ->
        if a[key] < b[key]
            return -reverse
        if a[key] > b[key]
            return reverse
        0
