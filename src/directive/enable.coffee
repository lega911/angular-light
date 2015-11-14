
alight.d.al.enable = (cd, element, exp) ->
    setter = (value) ->
        if value
            f$.removeAttr element, 'disabled'
        else
            f$.attr element, 'disabled', 'disabled'

    cd.watch exp, setter,
        readOnly: true
        init: true


alight.d.al.disable = (cd, element, exp) ->
    setter = (value) ->
        if value
            f$.attr element, 'disabled', 'disabled'
        else
            f$.removeAttr element, 'disabled'

    cd.watch exp, setter,
        readOnly: true
        init: true
