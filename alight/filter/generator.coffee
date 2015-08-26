
alight.filters.generator = (exp, scope) ->
    list = []
    (size) ->
        if list.length >= size
            list.length = size
        else
            while list.length < size
                list.push {}
        list
