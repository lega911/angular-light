
alight.d.al.text = (scope, element, name) ->
    self =
        start: ->
            self.watchModel()
            return
        updateDom: (value) ->
            value ?= ''
            if element.textContent isnt undefined
                element.textContent = value
            else
                element.innerText = value
            '$scanNoChanges'
        watchModel: ->
            scope.$watch name, self.updateDom
            return
