
alight.text['::'] = (callback, expression, scope, env) ->
    scope.$watch expression, (value) ->
        env.finally value
    ,
        oneTime: true
    return
