
alight.d.al.checked =
    priority: 100
    init: (cd, element, name) ->
        self =
            start: ->
                self.onDom()
                self.watchModel()
            onDom: ->
                f$.on element, 'change', self.updateModel
                cd.watch '$destroy', self.offDom
            offDom: ->
                f$.off element, 'change', self.updateModel
            updateModel: ->
                value = f$.prop element, 'checked'
                cd.setValue name, value
                cd.scan
                    skipWatch: self.watch
            watchModel: ->
                self.watch = cd.watch name, self.updateDom
            updateDom: (value) ->
                f$.prop element, 'checked', !!value
                '$scanNoChanges'
