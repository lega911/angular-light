
alight.d.al.focused = (cd, element, name) ->
    safe =
        changing: false
        updateModel: (value) ->
            if safe.changing
                return
            safe.changing = true
            cd.setValue name, value
            cd.scan ->
                safe.changing = false

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
            if safe.changing
                return '$scanNoChanges'
            safe.changing = true
            if value
                f$.focus(element)
            else
                f$.blur(element)
            safe.changing = false
            '$scanNoChanges'

        watchModel: ->
            cd.watch name, safe.updateDom

        start: ->
            safe.onDom()
            safe.watchModel()
