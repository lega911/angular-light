
alight.core.fastBinding = fastBinding = (element) ->
    self = @
    self.textBindings = []
    self.attrBindings = []

    path = [0]
    walk = (element, deep) ->
        if element.nodeType is 1
            # attributes
            for attr in element.attributes
                if attr.value.indexOf(alight.utils.pars_start_tag) < 0
                    continue
                self.attrBindings.push
                    value: attr.value
                    name: attr.nodeName
                    path: path.slice()
            # child nodes
            for childElement, i in element.childNodes
                path.length = deep + 1
                path[deep] = i
                walk childElement, deep + 1
        else if element.nodeType is 3
            if element.nodeValue.indexOf(alight.utils.pars_start_tag) < 0
                return
            self.textBindings.push
                value: element.nodeValue
                path: path.slice()
        null

    walk element, 0

    @


fastBinding::bind = (cd, element) ->
    self = @

    for item in self.attrBindings
        childElement = element
        for n in item.path
            childElement = childElement.childNodes[n]

        setter = do (element=childElement, attrName=item.name) ->
            (result) ->
                f$.attr element, attrName, result
                '$scanNoChanges'

        cd.watchText item.value, setter,
            init: true

    for item in self.textBindings
        childElement = element
        for n in item.path
            childElement = childElement.childNodes[n]

        setter = do (element=childElement) ->
            (result) ->
                element.nodeValue = result
                '$scanNoChanges'

        cd.watchText item.value, setter,
            init: true

    null
