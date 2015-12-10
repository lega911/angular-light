
alight.d.al.focused = (scope, element, name) ->
    safe =
        updateModel: (value) ->
            if scope.$getValue(name) is value
                return
            scope.$setValue name, value
            scope.$scan
                skipWatch: self.watch
            return

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
            return

        updateDom: (value) ->
            if value
                element.focus()
            else
                element.blur()
            '$scanNoChanges'

        watchModel: ->
            self.watch = scope.$watch name, safe.updateDom
            return

        start: ->
            safe.onDom()
            safe.watchModel()
            return
