
alight.d.al.focused = (element, name, scope) ->
    watch = false
    safe =
        changing: false
        updateModel: (value) ->
            if safe.changing
                return
            safe.changing = true
            scope.$setValue name, value
            scope.$scan ->
                safe.changing = false

        onDom: ->
            von = ->
                safe.updateModel true
            voff = ->
                safe.updateModel false
            f$.on element, 'focus', von
            f$.on element, 'blur', voff
            scope.$watch '$destroy', ->
                f$.off element, 'focus', von
                f$.off element, 'blur', voff

        updateDom: (value) ->
            if safe.changing
                return
            safe.changing = true
            if value
                f$.focus(element)
            else
                f$.blur(element)
            safe.changing = false

        watchModel: ->
            watch = scope.$watch name, safe.updateDom,
                readOnly: true

        initDom: ->
            watch.fire()

        start: ->
            safe.onDom()
            safe.watchModel()
            safe.initDom()
