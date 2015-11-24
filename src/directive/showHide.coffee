
alight.d.al.show = (cd, element, exp) ->
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
            '$scanNoChanges'
        watchModel: ->
            cd.watch exp, self.updateDom
        start: ->
            self.watchModel()


alight.d.al.hide = (cd, element, exp, env) ->
    self = alight.d.al.show cd, element, exp, env
    self.updateDom = (value) ->
        if value
            self.hideDom()
        else
            self.showDom()
        '$scanNoChanges'
    self
