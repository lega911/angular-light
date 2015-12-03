
alight.d.al.checked =
    priority: 100
    link: (scope, element, name) ->
        self =
            start: ->
                self.onDom()
                self.watchModel()
            onDom: ->
                f$.on element, 'change', self.updateModel
                scope.$watch '$destroy', self.offDom
            offDom: ->
                f$.off element, 'change', self.updateModel
            updateModel: ->
                value = f$.prop element, 'checked'
                scope.$setValue name, value
                scope.$scan
                    skipWatch: self.watch
            watchModel: ->
                self.watch = scope.$watch name, self.updateDom
            updateDom: (value) ->
                f$.prop element, 'checked', !!value
                '$scanNoChanges'
