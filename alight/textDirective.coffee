
alight.text.bindonce = (callback, expression, scope, env) ->
    pe = alight.utils.parsExpression expression
    if pe.hasFilters
        throw 'Conflict: bindonce and filters, use one-time binding'
    else
        env.finally scope.$eval expression

alight.text.oneTimeBinding = (callback, expression, scope, env) ->
    w = scope.$watch expression, (value) ->
        if value is undefined
            return
        w.stop()
        env.finally value
    ,
        init: true
