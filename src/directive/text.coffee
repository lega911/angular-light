
alight.d.al.text = (scope, element, name, env) ->
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
            env.watch name, self.updateDom
            return
