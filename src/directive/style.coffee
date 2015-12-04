
alight.d.al.style = (scope, element, name) ->
    prev = {}
    setter = (style) ->
        for key, v of prev
            element.style[key] = ''

        prev = {}
        for k, v of style or {}
            key = k.replace /(-\w)/g, (m) ->
                m.substring(1).toUpperCase()
            prev[key] = v
            element.style[key] = v or ''

    scope.$watch name, setter,
        deep: true
