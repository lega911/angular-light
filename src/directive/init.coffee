
alight.d.al.init = (scope, element, exp, env) ->
    cd = env.changeDetector
    try
        fn = cd.compile exp,
            no_return: true
            input: ['$element']
        fn cd.locals, element
    catch e
        alight.exceptionHandler e, 'al-init, error in expression: ' + exp,
            exp: exp
            scope: scope
            cd: cd
            element: element
    return
