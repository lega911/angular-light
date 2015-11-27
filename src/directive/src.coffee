
alight.d.al.src = (scope, cd, element, name) ->
    setter = (value) ->
        if not value
            value = ''
        f$.attr element, 'src', value
        '$scanNoChanges'

    cd.watchText name, setter
