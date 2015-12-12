
# {{& form.name : someFunc($value, form.age) }}

alight.text['&'] = (callback, expression, scope, env) ->
    d = expression.split ':'

    fn = scope.$compile d[1],
        input: ['$value']

    scope.$watch d[0], (value) ->
        result = fn scope, value

        if window.Promise
            if result instanceof Promise
                result.then (value) ->
                    callback value
                    scope.$scan()
            else
                callback result
        else
            callback result
