
alight.d.al.readonly = (scope, element, exp) ->
    setter = (value) ->
        element.readOnly = !!value

    scope.$watch exp, setter,
        readOnly: true
