
alight.d.al.checked =
    priority: 100
    init: (node, element, name) ->
        watch = false
        self =
            changing: false
            start: ->
                self.onDom()
                self.watchModel()
                self.initDom()
            onDom: ->
                f$.on element, 'change', self.updateModel
                node.watch '$destroy', self.offDom
            offDom: ->
                f$.off element, 'change', self.updateModel
            updateModel: ->
                value = f$.prop element, 'checked'
                self.changing = true
                node.setValue name, value
                node.scan ->
                    self.changing = false
            watchModel: ->
                watch = node.watch name, self.updateDom
            updateDom: (value) ->
                if self.changing
                    return
                f$.prop element, 'checked', !!value
                '$scanNoChanges'
            initDom: ->
                watch.fire()
