
alight.filters.storeTo = (key, cd) ->
    (value) ->
        cd.setValue key, value
        value
