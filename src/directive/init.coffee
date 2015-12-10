
alight.d.al.init = (scope, element, exp) ->
    try
        fn = scope.$compile exp,
            no_return: true
        fn scope
    catch e
        alight.exceptionHandler e, 'al-init, error in expression: ' + exp,
            exp: exp
            scope: scope
            element: element
    return
