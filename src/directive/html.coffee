
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
    link: (scope, element, inputName, env) ->
        childCD = null
        baseElement = null
        topElement = null
        activeElement = null
        self =
            name: inputName
            updateDom: null
            watchMode: null  # model, literal, tpl
            #outerName: null
            start: ->
                self.parsing()
                self.prepare()
                self.watchModel()
                return
            parsing: ->
                self.updateDom = self.updateByHtml  # default
                if env.attrArgument
                    for k in env.attrArgument.split '.'
                        switch k
                            when 'id' then self.updateDom = self.updateById
                            when 'url' then self.updateDom = self.updateByUrl
                            when 'literal' then self.watchMode = 'literal'
                            when 'tpl' then self.watchMode = 'tpl'
                #d = self.name.match /^(.+)[^\:]\:\s*(\w+)$/
                #if d
                #    self.name = d[1]
                #    self.outerName = d[2]
                return
            prepare: ->
                baseElement = element
                topElement = document.createComment " #{env.attrName}: #{inputName} "
                f$.before element, topElement
                f$.remove element
                return
            loadHtml: (cfg) ->
                f$.ajax cfg
                return
            removeBlock: ->
                if childCD
                    childCD.destroy()
                    childCD = null
                if activeElement
                    self.removeDom activeElement
                    activeElement = null
                return
            insertBlock: (html) ->
                activeElement = baseElement.cloneNode false
                activeElement.innerHTML = html
                self.insertDom topElement, activeElement
                childCD = env.changeDetector.new()
                alight.bind childCD, activeElement,
                    skip_attr: env.skippedAttr()
                return
            updateByHtml: (html) ->
                self.removeBlock()
                if html
                    self.insertBlock html
                return
            updateById: (id) ->
                self.removeBlock()
                tpl = document.getElementById id
                if tpl
                    html = tpl.innerHTML
                    if html
                        self.insertBlock html
                return
            updateByUrl: (url) ->
                if not url
                    self.removeBlock()
                    return
                self.loadHtml
                    cache: true
                    url: url
                    success: (html) ->
                        self.removeBlock()
                        self.insertBlock html
                        return
                    error: self.removeBlock
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
