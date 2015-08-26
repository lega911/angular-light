
alight.d.al.text = (element, name, scope) ->
    watch = null
    self =
        start: ->
            self.watchModel()
            self.initDom()
        updateDom: (value) ->
            `if(value == null) value = ''`
            f$.text element, value
        watchModel: ->
            watch = scope.$watch name, self.updateDom,
                readOnly: true
        initDom: ->
            watch.fire()
