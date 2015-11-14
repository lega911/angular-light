
alight.d.al.cloak = (cd, element, name, env) ->
    f$.removeAttr element, env.attrName
    if name
        f$.removeClass element, name
