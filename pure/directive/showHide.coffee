
alight.d.al.show = (cd, element, exp) ->
    watch = null
    self =
        showDom: ->
            f$.show element
        hideDom: ->
            f$.hide element
        updateDom: (value) ->
            if value
                self.showDom()
            else
                self.hideDom()
        watchModel: ->
            watch = cd.watch exp, self.updateDom,
                readOnly: true
        initDom: ->
            watch.fire()
        start: ->
            self.watchModel()
            self.initDom()


alight.d.al.hide = (cd, element, exp, env) ->
    self = alight.d.al.show cd, element, exp, env
    self.updateDom = (value) ->
        if value
            self.hideDom()
        else
            self.showDom()
    self
