
alight.d.al.focused =
    priority: 20
    link: (scope, element, name, env) ->
        safe =
            updateModel: (value) ->
                if env.getValue(name) is value
                    return
                env.setValue name, value
                self.watch.refresh()
                env.scan()
                return

            onDom: ->
                von = ->
                    safe.updateModel true
                voff = ->
                    safe.updateModel false
                f$.on element, 'focus', von
                f$.on element, 'blur', voff
                env.watch '$destroy', ->
                    f$.off element, 'focus', von
                    f$.off element, 'blur', voff
                return

            updateDom: (value) ->
                if value
                    element.focus()
                else
                    element.blur()
                '$scanNoChanges'

            watchModel: ->
                self.watch = env.watch name, safe.updateDom
                return

            start: ->
                safe.onDom()
                safe.watchModel()
                return
