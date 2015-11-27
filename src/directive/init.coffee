
alight.d.al.init = (scope, cd, element, exp) ->
    try
        fn = cd.compile exp,
            no_return: true
        fn scope
    catch e
        alight.exceptionHandler e, 'al-init, error in expression: ' + exp,
            exp: exp
            cd: cd
            scope: scope
            element: element
