
alight.d.al.text = (scope, element, name) ->
    self =
        start: ->
            self.watchModel()
        updateDom: (value) ->
            value ?= ''
            f$.text element, value
            '$scanNoChanges'
        watchModel: ->
            scope.$watch name, self.updateDom
