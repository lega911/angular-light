
alight.d.al.text = (cd, element, name) ->
    watch = null
    self =
        start: ->
            self.watchModel()
            self.initDom()
        updateDom: (value) ->
            `if(value == null) value = ''`
            f$.text element, value
            '$scanNoChanges'
        watchModel: ->
            watch = cd.watch name, self.updateDom
        initDom: ->
            watch.fire()
