
###
    al-html="model"
    al-html:id=" 'templateId' "
    al-html:id.literal="templateId" // template id without 'quotes'
    al-html:url="model"
    al-html:url.tpl="/templates/{{templateId}}"
###

alight.d.al.html =
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
                self.updateDom = self.updateByHtml  # default
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
                self.baseElement = element
                self.topElement = document.createComment " #{env.attrName}: #{inputName} "
                f$.before element, self.topElement
                f$.remove element
                return
            loadHtml: (cfg) ->
                f$.ajax cfg
                return
            removeBlock: ->
                if self.childCD
                    self.childCD.destroy()
                    self.childCD = null
                if self.activeElement
                    self.removeDom self.activeElement
                    self.activeElement = null
                return
            insertBlock: (html) ->
                self.activeElement = self.baseElement.cloneNode false
                self.activeElement.innerHTML = html
                self.insertDom self.topElement, self.activeElement
                self.childCD = env.changeDetector.new()
                alight.bind self.childCD, self.activeElement,
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
