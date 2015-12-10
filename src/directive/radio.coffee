
alight.d.al.radio =
    priority: 10
    link: (scope, element, name, env) ->
        self =
            start: ->
                self.makeValue()
                self.onDom()
                self.watchModel()
                return
            makeValue: ->
                key = env.takeAttr 'al-value'
                if key
                    value = scope.$eval key
                else
                    value = env.takeAttr 'value'
                self.value = value
                return
            onDom: ->
                f$.on element, 'change', self.updateModel
                scope.$watch '$destroy', self.offDom
                return
            offDom: ->
                f$.off element, 'change', self.updateModel
                return
            updateModel: ->
                scope.$setValue name, self.value
                scope.$scan
                    skipWatch: self.watch
                return
            watchModel: ->
                self.watch = scope.$watch name, self.updateDom
                return
            updateDom: (value) ->
                element.checked = value is self.value
                '$scanNoChanges'
