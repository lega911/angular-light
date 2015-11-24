
alight.d.al.value = (cd, element, variable) ->
    self =
        changing: false
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
                self.changing = true
                cd.setValue variable, value
                cd.scan ->
                    self.changing = false
        watchModel: ->
            cd.watch variable, self.updateDom
        updateDom: (value) ->
            if self.changing
                return
            value ?= ''
            f$.val element, value
            '$scanNoChanges'
        start: ->
            self.onDom()
            self.watchModel()
