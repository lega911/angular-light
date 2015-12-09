
alight.d.al.text = (scope, element, name) ->
    self =
        start: ->
            self.watchModel()
        updateDom: (value) ->
            value ?= ''
            if element.textContent isnt undefined
                element.textContent = value
            else
                element.innerText = value
            '$scanNoChanges'
        watchModel: ->
            scope.$watch name, self.updateDom
