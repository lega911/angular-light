
alight.d.al.readonly = (scope, cd, element, exp) ->
    setter = (value) ->
        f$.prop element, 'readOnly', !!value

    cd.watch exp, setter,
        readOnly: true
