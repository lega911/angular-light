
alight.d.al.init = (scope, element, exp, env) ->
    env.fastBinding = true
    cd = env.changeDetector
    input = ['$element']
    if env.attrArgument is 'window'
        input.push 'window'
    try
        fn = cd.compile exp,
            no_return: true
            input: input
        fn cd.locals, element, window
    catch e
        alight.exceptionHandler e, 'al-init, error in expression: ' + exp,
            exp: exp
            scope: scope
            cd: cd
            element: element
    return
