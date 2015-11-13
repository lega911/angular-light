
alight.d.bo.switch =
    priority: 500
    init: (cd, element, name, env) ->
        child = cd.new()
        child.$switch =
            value: child.eval name
            on: false

        alight.applyBindings child, element,
            skip_attr:env.skippedAttr()

        owner: true


alight.d.bo.switchWhen =
    priority: 500
    init: (cd, element, name) ->
        if cd.$switch.value != name
            f$.remove element
            return { owner:true }
        cd.$switch.on = true


alight.d.bo.switchDefault =
    priority: 500
    init: (cd, element, name) ->
        if cd.$switch.on
            f$.remove element
            return { owner:true }
        null

do ->
    makeBindOnceIf = (direct) ->
        self =
            priority: 700
            init: (cd, element, exp) ->
                value = cd.eval exp
                if !value is direct
                    f$.remove element
                    { owner:true }

    alight.d.bo.if = makeBindOnceIf true
    alight.d.bo.ifnot = makeBindOnceIf false
