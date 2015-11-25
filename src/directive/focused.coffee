
alight.d.al.focused = (cd, element, name) ->
    safe =
        updateModel: (value) ->
            if cd.getValue(name) is value
                return
            cd.setValue name, value
            cd.scan
                skipWatch: self.watch

        onDom: ->
            von = ->
                safe.updateModel true
            voff = ->
                safe.updateModel false
            f$.on element, 'focus', von
            f$.on element, 'blur', voff
            cd.watch '$destroy', ->
                f$.off element, 'focus', von
                f$.off element, 'blur', voff

        updateDom: (value) ->
            if value
                f$.focus(element)
            else
                f$.blur(element)
            '$scanNoChanges'

        watchModel: ->
            self.watch = cd.watch name, safe.updateDom

        start: ->
            safe.onDom()
            safe.watchModel()
