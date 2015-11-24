
alight.d.al.radio =
    priority: 10
    init: (cd, element, name, env) ->
        self =
            changing: false
            start: ->
                self.makeValue()
                self.onDom()
                self.watchModel()
                self.initDom()
            makeValue: ->
                key = env.takeAttr 'al-value'
                if key
                    value = cd.eval key
                else
                    value = env.takeAttr 'value'
                self.value = value
            onDom: ->
                f$.on element, 'change', self.updateModel
                cd.watch '$destroy', self.offDom
            offDom: ->
                f$.off element, 'change', self.updateModel
            updateModel: ->
                self.changing = true
                cd.setValue name, self.value
                cd.scan ->
                    self.changing = false
            watchModel: ->
                cd.watch name, self.updateDom
            updateDom: (value) ->
                if self.changing
                    return '$scanNoChanges'
                f$.prop element, 'checked', value is self.value
                '$scanNoChanges'
