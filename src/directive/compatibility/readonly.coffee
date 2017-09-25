
alight.d.al.readonly = (scope, element, exp) ->
    setter = (value) ->
        element.readOnly = !!value
        return

    @.watch exp, setter,
        readOnly: true
    return
