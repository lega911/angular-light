
alight.d.al.radio =
    priority: 10
    link: (scope, cd, element, name, env) ->
        self =
            start: ->
                self.makeValue()
                self.onDom()
                self.watchModel()
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
                cd.setValue name, self.value
                cd.scan
                    skipWatch: self.watch
            watchModel: ->
                self.watch = cd.watch name, self.updateDom
            updateDom: (value) ->
                f$.prop element, 'checked', value is self.value
                '$scanNoChanges'
