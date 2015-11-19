
alight.d.al.if =
    priority: 700
    init: (cd, element, name, env) ->
        self =
            owner: true
            item: null
            child: null
            base_element: null
            top_element: null
            watch: null
            start: ->
                self.prepare()
                self.watchModel()
                self.initUpdate()
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
                '$scanNoChanges'
            removeBlock: ->
                if not self.child
                    return
                self.child.$destroy()
                self.removeDom self.item
                self.child = null
                self.item = null
            insertBlock: ->
                if self.child
                    return
                self.item = f$.clone self.base_element
                self.insertDom self.top_element, self.item
                self.child = cd.new()
                alight.applyBindings self.child, self.item, { skip_attr:env.skippedAttr() }
            watchModel: ->
                self.watch = cd.watch name, self.updateDom
            initUpdate: ->
                self.watch.fire()
            removeDom: (element) ->
                f$.remove element
            insertDom: (base, element) ->
                f$.after base, element


alight.d.al.ifnot =
    priority: 700
    init: (cd, element, name, env) ->
        self = alight.d.al.if.init cd, element, name, env
        self.updateDom = (value) ->
            if value
                self.removeBlock()
            else
                self.insertBlock()
        self
