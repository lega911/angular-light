
alight.d.al.value =
    priority: 20
    init: (scope, element, variable) ->
        self =
            onDom: ->
                f$.on element, 'input', self.updateModel
                f$.on element, 'change', self.updateModel
                scope.$watch '$destroy', self.offDom
                return
            offDom: ->
                f$.off element, 'input', self.updateModel
                f$.off element, 'change', self.updateModel
                return
            updateModel: ->
                scope.$setValue variable, element.value
                scope.$scan
                    skipWatch: self.watch
                return
            watchModel: ->
                self.watch = scope.$watch variable, self.updateDom
                return
            updateDom: (value) ->
                value ?= ''
                element.value = value
                '$scanNoChanges'
            start: ->
                self.onDom()
                self.watchModel()
                return
