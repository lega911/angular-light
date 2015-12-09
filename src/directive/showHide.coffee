
alight.d.al.show = (scope, element, exp) ->
    self =
        showDom: ->
            f$.removeClass element, 'al-hide'
        hideDom: ->
            f$.addClass element, 'al-hide'
        updateDom: (value) ->
            if value
                self.showDom()
            else
                self.hideDom()
            '$scanNoChanges'
        watchModel: ->
            scope.$watch exp, self.updateDom
        start: ->
            self.watchModel()


alight.d.al.hide = (scope, element, exp, env) ->
    self = alight.d.al.show scope, element, exp, env
    self.updateDom = (value) ->
        if value
            self.hideDom()
        else
            self.showDom()
        '$scanNoChanges'
    self
