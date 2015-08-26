
alight.d.al.value = (element, variable, scope) ->
    watch = null
    self =
        changing: false
        onDom: ->
            f$.on element, 'input', self.updateModel
            f$.on element, 'change', self.updateModel
            scope.$watch '$destroy', self.offDom
        offDom: ->
            f$.off element, 'input', self.updateModel
            f$.off element, 'change', self.updateModel
        updateModel: ->
            alight.nextTick ->
                value = f$.val element
                self.changing = true
                scope.$setValue variable, value
                scope.$scan ->
                    self.changing = false
        watchModel: ->
            watch = scope.$watch variable, self.updateDom,
                readOnly: true
        updateDom: (value) ->
            if self.changing
                return
            value ?= ''
            f$.val element, value
        initDom: ->
            watch.fire()
        start: ->
            self.onDom()
            self.watchModel()
            self.initDom()
