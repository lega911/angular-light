
alight.d.al.value = (cd, element, variable) ->
    self =
        onDom: ->
            f$.on element, 'input', self.updateModel
            f$.on element, 'change', self.updateModel
            cd.watch '$destroy', self.offDom
        offDom: ->
            f$.off element, 'input', self.updateModel
            f$.off element, 'change', self.updateModel
        updateModel: ->
            alight.nextTick ->
                value = f$.val element
                cd.setValue variable, value
                cd.scan
                    skipWatch: self.watch
        watchModel: ->
            self.watch = cd.watch variable, self.updateDom
        updateDom: (value) ->
            value ?= ''
            f$.val element, value
            '$scanNoChanges'
        start: ->
            self.onDom()
            self.watchModel()
