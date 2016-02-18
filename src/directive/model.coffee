
# proxy for al-value, al-checked, al-radio, al-select, al-focused
alight.d.al.model =
    priority: 20
    link: (scope, element, value, env) ->
        name = element.nodeName.toLowerCase()
        if name is 'select'
            return alight.d.al.select.link scope, element, value, env
        if name is 'input'
            if element.type is 'checkbox'
                return alight.d.al.checked.link scope, element, value, env
            if element.type is 'radio'
                return alight.d.al.radio.link scope, element, value, env
        return alight.d.al.value.link scope, element, value, env
