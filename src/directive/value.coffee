
alight.d.al.value = (scope, element, variable) ->
    self =
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
                scope.$setValue variable, value
                scope.$scan
                    skipWatch: self.watch
        watchModel: ->
            self.watch = scope.$watch variable, self.updateDom
        updateDom: (value) ->
            value ?= ''
            f$.val element, value
            '$scanNoChanges'
        start: ->
            self.onDom()
            self.watchModel()
