
alight.d.al.init = (cd, element, exp) ->
    try
        fn = cd.compile exp,
            no_return: true
        fn cd.scope
    catch e
        alight.exceptionHandler e, 'al-init, error in expression: ' + exp,
            exp: exp
            cd: cd
            scope: cd.scope
            element: element
