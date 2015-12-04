
alight.d.bo.switch =
    priority: 500
    ChangeDetector: true
    link: (scope, element, name, env) ->
        cd = scope.$changeDetector
        cd.$switch =
            value: scope.$eval name
            on: false
        null


alight.d.bo.switchWhen =
    priority: 500
    link: (scope, element, name, env) ->
        cd = scope.$changeDetector
        if cd.$switch.value != name
            f$.remove element
            env.stopBinding = true
        else
            cd.$switch.on = true


alight.d.bo.switchDefault =
    priority: 500
    link: (scope, element, name, env) ->
        cd = scope.$changeDetector
        if cd.$switch.on
            f$.remove element
            env.stopBinding = true

do ->
    makeBindOnceIf = (direct) ->
        self =
            priority: 700
            link: (scope, element, exp, env) ->
                cd = scope.$changeDetector
                value = scope.$eval exp
                if !value is direct
                    f$.remove element
                    env.stopBinding = true

    alight.d.bo.if = makeBindOnceIf true
    alight.d.bo.ifnot = makeBindOnceIf false
