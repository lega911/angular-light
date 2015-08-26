
alight.d.bo.switch =
    priority: 500
    init: (element, name, scope, env) ->
        child = scope.$new()
        child.$switch =
            value: scope.$eval name
            on: false

        alight.applyBindings child, element, { skip_attr:env.skippedAttr() }

        owner: true


alight.d.bo.switchWhen =
    priority: 500
    init: (element, name, scope) ->
        if scope.$switch.value != name
            f$.remove element
            return { owner:true }
        scope.$switch.on = true


alight.d.bo.switchDefault =
    priority: 500
    init: (element, name, scope) ->
        if scope.$switch.on
            f$.remove element
            return { owner:true }
        null

do ->
    makeBindOnceIf = (direct) ->
        self =
            priority: 700
            init: (element, exp, scope) ->
                value = scope.$eval exp
                if !value is direct
                    f$.remove element
                    { owner:true }

    alight.d.bo.if = makeBindOnceIf true
    alight.d.bo.ifnot = makeBindOnceIf false
