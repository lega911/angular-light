
alight.d.al.src = (element, name, scope) ->
    setter = (value) ->
        if not value
            value = ''
        f$.attr element, 'src', value
        '$scanNoChanges'

    scope.$watchText name, setter,
        init: true
