
alight.d.al.value = (scope, element, variable, env) ->
    env.fastBinding = true
    self =
        onDom: ->
            f$.on element, 'input', self.updateModel
            f$.on element, 'change', self.updateModel
            env.watch '$destroy', self.offDom
            return
        offDom: ->
            f$.off element, 'input', self.updateModel
            f$.off element, 'change', self.updateModel
            return
        updateModel: ->
            env.setValue variable, element.value
            self.watch.refresh()
            env.scan()
            return
        watchModel: ->
            self.watch = env.watch variable, self.updateDom
            return
        updateDom: (value) ->
            value ?= ''
            element.value = value
            '$scanNoChanges'
        start: ->
            self.onDom()
            self.watchModel()
            return
