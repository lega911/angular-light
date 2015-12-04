
alight.d.al.enable = (scope, element, exp) ->
    setter = (value) ->
        if value
            f$.removeAttr element, 'disabled'
        else
            f$.attr element, 'disabled', 'disabled'

    scope.$watch exp, setter


alight.d.al.disable = (scope, element, exp) ->
    setter = (value) ->
        if value
            f$.attr element, 'disabled', 'disabled'
        else
            f$.removeAttr element, 'disabled'

    scope.$watch exp, setter
