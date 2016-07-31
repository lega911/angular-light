
alight.d.al.radio =
    priority: 20
    init: (scope, element, name, env) ->
        self =
            start: ->
                self.makeValue()
                self.onDom()
                self.watchModel()
                return
            makeValue: ->
                key = env.takeAttr 'al-value'
                if key
                    value = env.eval key
                else
                    value = env.takeAttr 'value'
                self.value = value
                return
            onDom: ->
                f$.on element, 'change', self.updateModel
                env.watch '$destroy', self.offDom
                return
            offDom: ->
                f$.off element, 'change', self.updateModel
                return
            updateModel: ->
                env.setValue name, self.value
                self.watch.refresh()
                env.scan()
                return
            watchModel: ->
                self.watch = env.watch name, self.updateDom
                return
            updateDom: (value) ->
                element.checked = value is self.value
                '$scanNoChanges'
