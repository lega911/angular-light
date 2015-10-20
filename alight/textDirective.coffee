
alight.text.bindonce = (callback, expression, scope, env) ->
    pe = alight.utils.parsExpression expression
    if pe.hasFilters
        throw 'Conflict: bindonce and filters, use one-time binding'
    else
        env.finally scope.$eval expression

alight.text.oneTimeBinding = (callback, expression, scope, env) ->
    scope.$watch expression, (value) ->
        env.finally value
    ,
        init: true
        oneTime: true
