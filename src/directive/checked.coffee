
alight.d.al.checked = (scope, element, name, env) ->
    env.fastBinding = true
    self =
        start: ->
            self.onDom()
            self.watchModel()
            return
        onDom: ->
            f$.on element, 'change', self.updateModel
            env.watch '$destroy', self.offDom
            return
        offDom: ->
            f$.off element, 'change', self.updateModel
            return
        updateModel: ->
            value = element.checked
            env.setValue name, value
            self.watch.refresh()
            env.scan()
            return
        watchModel: ->
            self.watch = env.watch name, self.updateDom
            return
        updateDom: (value) ->
            element.checked = !!value
            '$scanNoChanges'
