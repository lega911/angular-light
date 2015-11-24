
alight.d.al.checked =
    priority: 100
    init: (cd, element, name) ->
        self =
            changing: false
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
                self.changing = true
                cd.setValue name, value
                cd.scan ->
                    self.changing = false
            watchModel: ->
                cd.watch name, self.updateDom
            updateDom: (value) ->
                if self.changing
                    return '$scanNoChanges'
                f$.prop element, 'checked', !!value
                '$scanNoChanges'
