
alight.d.al.src = (scope, element, name) ->
    setter = (value) ->
        if not value
            value = ''
        f$.attr element, 'src', value
        '$scanNoChanges'

    scope.$watchText name, setter
