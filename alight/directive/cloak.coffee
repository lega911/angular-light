
alight.d.al.cloak = (element, name, scope, env) ->
    f$.removeAttr element, env.attrName
    if name
        f$.removeClass element, name
