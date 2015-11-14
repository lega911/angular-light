
alight.d.al.readonly = (cd, element, exp) ->
    setter = (value) ->
        f$.prop element, 'readOnly', !!value

    cd.watch exp, setter,
        readOnly: true
        init: true
