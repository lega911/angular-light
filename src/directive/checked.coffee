
alight.d.al.checked = (scope, element, name, env) ->
    env.fastBinding = true

    env.on element, 'change', ->
        env.setValue name, element.checked
        watch.refresh()
        env.scan()
        return

    watch = env.watch name, (value) ->
        element.checked = !!value
        '$scanNoChanges'

    return