
# {{& form.name : someFunc($value, form.age) }}

alight.text['&'] = (callback, expression, scope, env) ->
    d = expression.split ':'
    cd = env.changeDetector

    fn = cd.compile d[1],
        input: ['$value']

    cd.watch d[0], (value) ->
        result = fn scope, value

        if f$.isPromise result
            result.then (value) ->
                callback value
                cd.scan()
        else
            callback result
