
alight.d.al.radio = (scope, element, name, env) ->
    key = env.takeAttr 'al-value'
    if key
        value = env.eval key
    else
        value = env.takeAttr 'value'

    env.on element, 'change', ->
        env.setValue name, value
        watch.refresh()
        env.scan()
        return

    watch = env.watch name, (newValue) ->
        element.checked = value is newValue
        '$scanNoChanges'
