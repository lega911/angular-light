
alight.d.al.cloak = (scope, cd, element, name, env) ->
    f$.removeAttr element, env.attrName
    if name
        f$.removeClass element, name
