
alight.d.al.text = (scope, cd, element, name) ->
    self =
        start: ->
            self.watchModel()
        updateDom: (value) ->
            `if(value == null) value = ''`
            f$.text element, value
            '$scanNoChanges'
        watchModel: ->
            cd.watch name, self.updateDom
