
alight.d.al.cloak = (scope, element, name, env) ->
    element.removeAttribute env.attrName
    if name
        f$.removeClass element, name
