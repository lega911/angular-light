
alight.d.al.src = (scope, element, name) ->
    setter = (value) ->
        if not value
            value = ''
        element.setAttribute 'src', value
        '$scanNoChanges'

    @.watchText name, setter
    return
