
alight.d.bo.switch =
    priority: 500
    ChangeDetector: true
    link: (scope, element, name, env) ->
        env.changeDetector.$switch =
            value: env.eval name
            on: false
        return


alight.d.bo.switchWhen =
    priority: 500
    link: (scope, element, name, env) ->
        cd = env.changeDetector
        if cd.$switch.value != name
            f$.remove element
            env.stopBinding = true
        else
            cd.$switch.on = true
        return


alight.d.bo.switchDefault =
    priority: 500
    link: (scope, element, name, env) ->
        if env.changeDetector.$switch.on
            f$.remove element
            env.stopBinding = true
        return

do ->
    makeBindOnceIf = (direct) ->
        self =
            priority: 700
            link: (scope, element, exp, env) ->
                value = env.eval exp
                if !value is direct
                    f$.remove element
                    env.stopBinding = true
                return

    alight.d.bo.if = makeBindOnceIf true
    alight.d.bo.ifnot = makeBindOnceIf false
