
alight.text.bindonce = (callback, expression, cd, env) ->
    ce = alight.utils.compile.expression expression
    if ce.filters
        throw 'Conflict: bindonce and filters, use one-time binding'
    env.finally ce.fn cd.scope

alight.text.oneTimeBinding = (callback, expression, cd, env) ->
    cd.watch expression, (value) ->
        env.finally value
    ,
        oneTime: true
