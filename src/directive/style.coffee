
alight.d.al.style = (scope, cd, element, name) ->
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

    cd.watch name, setter,
        deep: true
