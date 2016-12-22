
alight.d.al.init = (scope, element, exp, env) ->
    if alight.option.removeAttribute
        element.removeAttribute env.attrName
        if env.fbElement
            env.fbElement.removeAttribute env.attrName
    cd = env.changeDetector
    input = ['$element']
    if env.attrArgument is 'window'
        input.push 'window'
    try
        fn = cd.compile exp,
            no_return: true
            input: input
        env.fastBinding = fb = (scope, element, exp, env) ->
            fn env.changeDetector.locals, element, window
        fb scope, element, exp, env
    catch e
        alight.exceptionHandler e, 'al-init, error in expression: ' + exp,
            exp: exp
            scope: scope
            cd: cd
            element: element
        env.fastBinding = ->
    return
