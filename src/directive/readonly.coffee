
alight.d.al.readonly = (scope, element, exp) ->
    setter = (value) ->
        f$.prop element, 'readOnly', !!value

    scope.$watch exp, setter,
        readOnly: true
