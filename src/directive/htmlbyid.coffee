
alight.d.al.htmlById =
    priority: 100
    stopBinding: true
    link: (parentScope, element, name, env) ->
        parentCD = env.changeDetector
        childCD = null
        outerName = null

        j = name.indexOf ':'
        if j > 0
            outerName = name.slice(j+1).trim()
            name = name.slice 0, j

        setter = (templateId) ->
            if childCD
                childCD.destroy()
                childCD = null
            if not templateId
                element.innerHTML = ''
                return

            templateElement = document.getElementById templateId
            if not templateElement
                element.innerHTML = ''
                return
            element.innerHTML = templateElement.innerHTML
            innerName = templateElement.getAttribute('name') or templateId

            if outerName
                # transparent scope
                ChildScope = ->
                ChildScope:: = parentScope

                scope = new ChildScope
                scope.$$root = parentScope.$$root or parentScope
                scope.$rootChangeDetector = childCD = parentCD.new scope
                scope.$changeDetector = null
                scope.$parent = parentScope

                if outerName.slice(0, 2) is '::'
                    oneTime = true
                    outerName = outerName.slice 2

                childCD.watch '$parent.' + outerName, (outerValue) ->
                    scope[innerName] = outerValue
                ,
                    oneTime: oneTime
            else
                # no scope
                childCD = parentCD.new()

            alight.bind childCD, element,
                skip_attr: env.skippedAttr()
            return

        parentCD.watch name, setter
        return
