
alight.d.al.value = (scope, element, variable, env) ->
    env.fastBinding = true

    updateModel = ->
        env.setValue variable, element.value
        watch.refresh()
        env.scan()
        return

    f$.on element, 'input', updateModel
    f$.on element, 'change', updateModel
    env.watch '$destroy', ->
        f$.off element, 'input', updateModel
        f$.off element, 'change', updateModel

    watch = env.watch variable, (value) ->
        value ?= ''
        element.value = value
        '$scanNoChanges'
