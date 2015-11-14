
alight.d.al.value = (node, element, variable) ->
    watch = null
    self =
        changing: false
        onDom: ->
            f$.on element, 'input', self.updateModel
            f$.on element, 'change', self.updateModel
            node.watch '$destroy', self.offDom
        offDom: ->
            f$.off element, 'input', self.updateModel
            f$.off element, 'change', self.updateModel
        updateModel: ->
            alight.nextTick ->
                value = f$.val element
                self.changing = true
                node.setValue variable, value
                node.scan ->
                    self.changing = false
        watchModel: ->
            watch = node.watch variable, self.updateDom
        updateDom: (value) ->
            if self.changing
                return
            value ?= ''
            f$.val element, value
            '$scanNoChanges'
        initDom: ->
            watch.fire()
        start: ->
            self.onDom()
            self.watchModel()
            self.initDom()
