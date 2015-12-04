
alight.d.al.if =
    priority: 700
    stopBinding: true
    link: (scope, element, name, env) ->
        self =
            item: null
            childCD: null
            base_element: null
            top_element: null
            start: ->
                self.prepare()
                self.watchModel()
            prepare: ->
                self.base_element = element
                self.top_element = f$.createComment " #{env.attrName}: #{name} "
                f$.before element, self.top_element
                f$.remove element
            updateDom: (value) ->
                if value
                    self.insertBlock value
                else
                    self.removeBlock()
            removeBlock: ->
                if not self.childCD
                    return
                self.childCD.destroy()
                self.childCD = null
                self.removeDom self.item
                self.item = null
            insertBlock: ->
                if self.childCD
                    return
                self.item = f$.clone self.base_element
                self.insertDom self.top_element, self.item
                self.childCD = env.changeDetector.new()

                alight.bind self.childCD, self.item,
                    skip_attr: env.skippedAttr()    
            watchModel: ->
                scope.$watch name, self.updateDom
            removeDom: (element) ->
                f$.remove element
            insertDom: (base, element) ->
                f$.after base, element


alight.d.al.ifnot =
    priority: 700
    stopBinding: true
    link: (scope, element, name, env) ->
        self = alight.d.al.if.link scope, element, name, env
        self.updateDom = (value) ->
            if value
                self.removeBlock()
            else
                self.insertBlock()
        self
