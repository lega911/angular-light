
alight.d.al.checked = (scope, element, name, env) ->
    env.fastBinding = true

    updateModel = ->
        env.setValue name, element.checked
        watch.refresh()
        env.scan()
        return

    f$.on element, 'change', updateModel
    env.watch '$destroy', ->
        f$.off element, 'change', updateModel        

    watch = env.watch name, (value) ->
        element.checked = !!value
        '$scanNoChanges'

    return