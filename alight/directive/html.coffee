
alight.d.al.html =
    priority: 100
    init: (element, name, scope, env) ->
        child = null
        setter = (html) ->
            if child
                child.$destroy()
                child = null
            if not html
                f$.html element, ''
                return
            f$.html element, html
            child = scope.$new()
            alight.applyBindings child, element, { skip_attr:env.skippedAttr() }

        scope.$watch name, setter,
            readOnly: true
            init: true

        owner: true
