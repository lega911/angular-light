
alight.d.al.checked =
    priority: 100
    init: (element, name, scope) ->
        watch = false
        self =
            changing: false
            start: ->
                self.onDom()
                self.watchModel()
                self.initDom()
            onDom: ->
                f$.on element, 'change', self.updateModel
                scope.$watch '$destroy', self.offDom
            offDom: ->
                f$.off element, 'change', self.updateModel
            updateModel: ->
                value = f$.prop element, 'checked'
                self.changing = true
                scope.$setValue name, value
                scope.$scan ->
                    self.changing = false
            watchModel: ->
                watch = scope.$watch name, self.updateDom,
                    readOnly: true
            updateDom: (value) ->
                if self.changing
                    return
                f$.prop element, 'checked', !!value
            initDom: ->
                watch.fire()
