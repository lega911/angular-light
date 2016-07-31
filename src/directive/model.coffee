
# proxy for al-value, al-checked, al-radio, al-select, al-focused
alight.d.al.model =
    priority: 20
    init: (scope, element, value, env) ->
        name = element.nodeName.toLowerCase()
        if name is 'select'
            return alight.d.al.select.link.call @, scope, element, value, env
        if name is 'input'
            if element.type is 'checkbox'
                return alight.d.al.checked.init.call @, scope, element, value, env
            if element.type is 'radio'
                return alight.d.al.radio.init.call @, scope, element, value, env
        return alight.d.al.value.init.call @, scope, element, value, env
