
alight.d.al.html =
    priority: 100
    stopBinding: true
    link: (scope, element, name, env) ->
        cd = env.changeDetector
        child = null
        setter = (html) ->
            if child
                child.destroy()
                child = null
            if not html
                element.innerHTML = ''
                return
            element.innerHTML = html
            child = cd.new()
            alight.bind child, element,
                skip_attr: env.skippedAttr()
            return

        cd.watch name, setter
        return
