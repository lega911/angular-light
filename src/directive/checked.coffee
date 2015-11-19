
alight.d.al.checked =
    priority: 100
    init: (cd, element, name) ->
        watch = false
        self =
            changing: false
            start: ->
                self.onDom()
                self.watchModel()
                self.initDom()
            onDom: ->
                f$.on element, 'change', self.updateModel
                cd.watch '$destroy', self.offDom
            offDom: ->
                f$.off element, 'change', self.updateModel
            updateModel: ->
                value = f$.prop element, 'checked'
                self.changing = true
                cd.setValue name, value
                cd.scan ->
                    self.changing = false
            watchModel: ->
                watch = cd.watch name, self.updateDom
            updateDom: (value) ->
                if self.changing
                    return
                f$.prop element, 'checked', !!value
                '$scanNoChanges'
            initDom: ->
                watch.fire()
