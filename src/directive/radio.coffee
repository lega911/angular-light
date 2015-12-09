
alight.d.al.radio =
    priority: 10
    link: (scope, element, name, env) ->
        self =
            start: ->
                self.makeValue()
                self.onDom()
                self.watchModel()
            makeValue: ->
                key = env.takeAttr 'al-value'
                if key
                    value = scope.$eval key
                else
                    value = env.takeAttr 'value'
                self.value = value
            onDom: ->
                f$.on element, 'change', self.updateModel
                scope.$watch '$destroy', self.offDom
            offDom: ->
                f$.off element, 'change', self.updateModel
            updateModel: ->
                scope.$setValue name, self.value
                scope.$scan
                    skipWatch: self.watch
            watchModel: ->
                self.watch = scope.$watch name, self.updateDom
            updateDom: (value) ->
                element.checked = value is self.value
                '$scanNoChanges'
