
alight.text['::'] = (callback, expression, scope, env) ->
    env.changeDetector.watch expression, (value) ->
        env.finally value
    ,
        oneTime: true
    return
