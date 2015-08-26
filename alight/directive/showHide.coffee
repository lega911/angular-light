
alight.d.al.show = (element, exp, scope) ->
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
            watch = scope.$watch exp, self.updateDom,
                readOnly: true
        initDom: ->
            watch.fire()
        start: ->
            self.watchModel()
            self.initDom()


alight.d.al.hide = (element, exp, scope, env) ->
    self = alight.d.al.show element, exp, scope, env
    self.updateDom = (value) ->
        if value
            self.hideDom()
        else
            self.showDom()
    self
