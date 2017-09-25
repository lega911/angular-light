
alight.d.al.value = (scope, element, variable, env) ->
    env.fastBinding = true

    updateModel = ->
        env.setValue variable, element.value
        watch.refresh()
        env.scan()
        return

    env.on element, 'input', updateModel
    env.on element, 'change', updateModel

    watch = env.watch variable, (value) ->
        value ?= ''
        element.value = value
        '$scanNoChanges'
