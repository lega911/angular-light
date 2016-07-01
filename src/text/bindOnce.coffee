
alight.text['='] = (callback, expression, scope, env) ->
    ce = alight.utils.compile.expression expression
    if ce.filters
        throw 'Conflict: bindonce and filters, use one-time binding'
    env.finally ce.fn env.changeDetector.locals
    return
