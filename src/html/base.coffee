
###
    al-html="model"
    al-html:id=" 'templateId' "
    al-html:id.literal="templateId" // template id without 'quotes'
    al-html:url="model"
    al-html:url.tpl="/templates/{{templateId}}"
###

alight.d.al.html =
    restrict: 'AM'
    priority: 100
    modifier: {}
    link: (scope, element, inputName, env) ->
        if env.elementCanBeRemoved and element.nodeType isnt 8
            alight.exceptionHandler null, "#{env.attrName} can't control element because of #{env.elementCanBeRemoved}",
                scope: scope
                element: element
                value: inputName
                env: env
            return {}
        env.stopBinding = true
        self =
            baseElement: null
            topElement: null
            activeElement: null
            childCD: null

            name: inputName
            watchMode: null  # model, literal, tpl
            start: ->
                self.parsing()
                self.prepare()
                self.watchModel()
                return
            parsing: ->
                if env.attrArgument
                    for modifierName in env.attrArgument.split '.'
                        if modifierName is 'literal'
                            self.watchMode = 'literal'
                            continue
                        if modifierName is 'tpl'
                            self.watchMode = 'tpl'
                            continue
                        if not alight.d.al.html.modifier[modifierName]
                            continue
                        alight.d.al.html.modifier[modifierName] self,
                            scope: scope
                            element: element
                            inputName: inputName
                            env: env
                return
            prepare: ->
                if element.nodeType is 8
                    self.baseElement = null
                    self.topElement = element
                else
                    self.baseElement = element
                    self.topElement = document.createComment " #{env.attrName}: #{inputName} "
                    f$.before element, self.topElement
                    f$.remove element
                return
            removeBlock: ->
                if self.childCD
                    self.childCD.destroy()
                    self.childCD = null
                if self.activeElement
                    if Array.isArray self.activeElement
                        for el in self.activeElement
                            self.removeDom el
                    else
                        self.removeDom self.activeElement
                    self.activeElement = null
                return
            insertBlock: (html) ->
                if self.baseElement
                    self.activeElement = self.baseElement.cloneNode false
                    self.activeElement.innerHTML = html

                    self.insertDom self.topElement, self.activeElement
                    self.childCD = env.changeDetector.new()
                    alight.bind self.childCD, self.activeElement,
                        skip_attr: env.skippedAttr()
                        elementCanBeRemoved: env.attrName
                else
                    t = document.createElement 'body'
                    t.innerHTML = html

                    current = self.topElement
                    self.activeElement = []
                    self.childCD = env.changeDetector.new()
                    while el=t.firstChild
                        self.insertDom current, el
                        current = el
                        self.activeElement.push el

                        alight.bind self.childCD, current,
                            skip_attr: env.skippedAttr()
                            elementCanBeRemoved: env.attrName
                return
            updateDom: (html) ->
                self.removeBlock()
                if html
                    self.insertBlock html
                return
            removeDom: (element) ->
                f$.remove element
                return
            insertDom: (base, element) ->
                f$.after base, element
                return
            watchModel: ->
                if self.watchMode is 'literal'
                    self.updateDom self.name
                else if self.watchMode is 'tpl'
                    env.watchText self.name, self.updateDom
                else
                    env.watch self.name, self.updateDom
                return
