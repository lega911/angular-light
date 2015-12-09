
alight.d.al.enable = (scope, element, exp) ->
    setter = (value) ->
        if value
            element.removeAttribute 'disabled'
        else
            element.setAttribute 'disabled', 'disabled'

    scope.$watch exp, setter


alight.d.al.disable = (scope, element, exp) ->
    setter = (value) ->
        if value
            element.setAttribute 'disabled', 'disabled'
        else
            element.removeAttribute 'disabled'

    scope.$watch exp, setter
