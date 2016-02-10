
alight.d.al.html.modifier.scope = (self, option) ->
    d = self.name.match /(.+)\:\s*\:\:(\w+)$/
    if d
        oneTime = true
    else
        oneTime = false
        d = self.name.match /(.+)\:\s*(\w+)$/
        if not d
            throw 'Wrong expression ' + self.name
    self.name = d[1]
    outerName = d[2]
    innerName = 'outer'

    self.insertBlock = (html) ->
        self.activeElement = self.baseElement.cloneNode false
        self.activeElement.innerHTML = html
        self.insertDom self.topElement, self.activeElement

        # transparent scope
        parentScope = option.scope
        ChildScope = ->
        ChildScope:: = parentScope

        scope = new ChildScope
        scope.$$root = parentScope.$$root or parentScope
        scope.$rootChangeDetector = self.childCD = option.env.changeDetector.new scope
        scope.$changeDetector = null
        scope.$parent = parentScope

        self.childCD.watch '$parent.' + outerName, (outerValue) ->
            scope[innerName] = outerValue
        ,
            oneTime: oneTime

        alight.bind self.childCD, self.activeElement,
            skip_attr: option.env.skippedAttr()
        return
