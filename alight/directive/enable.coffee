
alight.d.al.enable = (element, exp, scope) ->
    setter = (value) ->
        if value
            f$.removeAttr element, 'disabled'
        else
            f$.attr element, 'disabled', 'disabled'

    scope.$watch exp, setter,
        readOnly: true
        init: true


alight.d.al.disable = (element, exp, scope) ->
    setter = (value) ->
        if value
            f$.attr element, 'disabled', 'disabled'
        else
            f$.removeAttr element, 'disabled'

    scope.$watch exp, setter,
        readOnly: true
        init: true
