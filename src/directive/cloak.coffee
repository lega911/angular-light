
alight.d.al.cloak = (scope, element, name, env) ->
    f$.removeAttr element, env.attrName
    if name
        f$.removeClass element, name
