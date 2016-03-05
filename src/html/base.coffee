
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
    stopBinding: true
    modifier: {}
    link: (scope, element, inputName, env) ->
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
                    if self.domOptimization
                        alight.utils.optmizeElement self.activeElement

                    self.insertDom self.topElement, self.activeElement
                    self.childCD = env.changeDetector.new()
                    alight.bind self.childCD, self.activeElement,
                        skip_attr: env.skippedAttr()
                else
                    t = document.createElement 'body'
                    t.innerHTML = html
                    if self.domOptimization
                        alight.utils.optmizeElement t

                    current = self.topElement
                    self.activeElement = []
                    self.childCD = env.changeDetector.new()
                    while el=t.firstChild
                        self.insertDom current, el
                        current = el
                        self.activeElement.push el

                        alight.bind self.childCD, current,
                            skip_attr: env.skippedAttr()
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
                    scope.$watchText self.name, self.updateDom
                else
                    scope.$watch self.name, self.updateDom
                return
