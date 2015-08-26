
alight.d.al.readonly = (element, exp, scope) ->
    setter = (value) ->
        f$.prop element, 'readOnly', !!value

    scope.$watch exp, setter,
        readOnly: true
        init: true
