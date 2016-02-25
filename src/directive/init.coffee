
alight.d.al.init = (scope, element, exp) ->
    try
        fn = scope.$compile exp,
            no_return: true
            input: ['$element']
        fn scope, element
    catch e
        alight.exceptionHandler e, 'al-init, error in expression: ' + exp,
            exp: exp
            scope: scope
            element: element
    return
