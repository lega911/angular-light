
alight.text.bindonce = (callback, expression, cd, env) ->
    pe = alight.utils.parsExpression expression
    if pe.hasFilters
        throw 'Conflict: bindonce and filters, use one-time binding'
    else
        env.finally cd.eval expression

alight.text.oneTimeBinding = (callback, expression, cd, env) ->
    cd.watch expression, (value) ->
        env.finally value
    ,
        oneTime: true
