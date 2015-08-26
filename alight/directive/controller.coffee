
alight.d.al.controller =
    priority: 500
    restrict: 'AE'
    init: (element, name, scope, env) ->
        self =
            owner: true
            start: ->
                newScope = scope.$new()
                self.callController newScope
                alight.applyBindings newScope, element, { skip_attr:env.skippedAttr() }
            callController: (newScope) ->
                if name
                    d = name.split ' as '
                    ctrl = alight.getController d[0], newScope
                    if d[1]
                        newScope[d[1]] = new ctrl(newScope)
                    else
                        ctrl newScope
        self
