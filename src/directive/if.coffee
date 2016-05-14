
alight.d.al.if =
    priority: 700
    link: (scope, element, name, env) ->
        if env.elementCanBeRemoved
            alight.exceptionHandler null, "#{env.attrName} can't control element because of #{env.elementCanBeRemoved}",
                scope: scope
                element: element
                value: name
                env: env
            return {}
        env.stopBinding = true
        self =
            item: null
            childCD: null
            base_element: null
            top_element: null
            start: ->
                self.prepare()
                self.watchModel()
                return
            prepare: ->
                self.base_element = element
                self.top_element = document.createComment " #{env.attrName}: #{name} "
                f$.before element, self.top_element
                f$.remove element
                return
            updateDom: (value) ->
                if value
                    self.insertBlock value
                else
                    self.removeBlock()
                return
            removeBlock: ->
                if not self.childCD
                    return
                self.childCD.destroy()
                self.childCD = null
                self.removeDom self.item
                self.item = null
                return
            insertBlock: ->
                if self.childCD
                    return
                self.item = self.base_element.cloneNode true
                self.insertDom self.top_element, self.item
                self.childCD = env.changeDetector.new()

                alight.bind self.childCD, self.item,
                    skip_attr: env.skippedAttr()
                    elementCanBeRemoved: env.attrName
                return
            watchModel: ->
                scope.$watch name, self.updateDom
                return
            removeDom: (element) ->
                f$.remove element
                return
            insertDom: (base, element) ->
                f$.after base, element
                return


alight.d.al.ifnot =
    priority: 700
    link: (scope, element, name, env) ->
        self = alight.d.al.if.link scope, element, name, env
        self.updateDom = (value) ->
            if value
                self.removeBlock()
            else
                self.insertBlock()
            return
        self
