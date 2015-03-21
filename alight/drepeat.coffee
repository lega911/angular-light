
###
    al-repeat="item in list" al-controller="itemController"
    "item in list"
    "item in list | filter"
    "item in list | filter track by trackExpression"
    "item in list track by $index"
    "item in list track by $id(item)"
    "item in list track by item.id"
    "item in list | filter store to filteredList"
    "item in list | filter track by trackExpression store to filteredList"
###

alight.directives.al.repeat =
    priority: 1000
    init: (element, exp, scope, env) ->
        self =
            owner: true
            start: ->
                self.prepare()
                self.parsExpression()
                self.prepareDom()
                self.watchModel()
                self.initUpdateDom()

            prepare: ->
                # get controller
                controllerName = env.takeAttr 'al-controller'
                if controllerName
                    alController = alight.directives.al.controller.init null, controllerName, null
                    self.childController = alController.callController
                else
                    self.childController = null

            parsExpression: ->
                s = exp

                # store to
                r = s.match /(.*) store to ([\w\.]+)/
                if r
                    self.storeTo = r[2]
                    s = r[1]

                # track by
                r = s.match /(.*) track by ([\w\.\$\(\)]+)/
                if r
                    self.trackExpression = r[2]
                    s = r[1]

                # item in list
                r = s.match /\s*(\w+)\s+in\s+(.+)/
                if not r
                    throw 'Wrong repeat: ' + exp
                self.nameOfKey = r[1]
                self.expression = r[2]

            watchModel: ->
                #self.watch = scope.$watch self.expression, self.updateDom, { isArray:true, readOnly:!self.storeTo }
                self.watch = scope.$watch self.expression, self.updateDom,
                    isArray: true

            initUpdateDom: ->
                self.updateDom self.watch.value

            prepareDom: ->
                self.base_element = element
                self.top_element = f$.createComment " #{exp} "
                f$.before element, self.top_element
                f$.remove element

            makeChild: (item, index, list) ->
                child_scope = scope.$new()
                self.updateChild child_scope, item, index, list
                if self.childController
                    self.childController child_scope
                child_scope

            updateChild: (child_scope, item, index, list) ->
                child_scope[self.nameOfKey] = item
                child_scope.$index = index
                child_scope.$first = index is 0
                child_scope.$last = index is list.length-1

            rawUpdateDom: (removes, inserts) ->
                for e in removes
                    f$.remove e
                for it in inserts
                    f$.after it.after, it.element
                null

            updateDom: do ->
                nodes = []
                node_by_id = null
                
                node_set = null
                node_get = null
                node_del = null
                index = 0

                (list) ->
                    # make mapper
                    if not node_get
                        if self.trackExpression is '$index'
                            node_by_id = {}
                            node_get = (item) ->
                                $id = index
                                node_by_id[$id] or null

                            node_del = (node) ->
                                $id = node.$id
                                if $id
                                    delete node_by_id[$id]
                                null

                            node_set = (item, node) ->
                                $id = index
                                node.$id = $id
                                node_by_id[$id] = node
                                null
                        else
                            if self.trackExpression
                                node_by_id = {}
                                _getId = scope.$compile self.trackExpression, { input:['$id', self.nameOfKey] }
                                _id = (item) ->
                                    id = item.$alite_id
                                    if id
                                        return id
                                    id = item.$alite_id = alight.utilits.getId()
                                    id

                                node_get = (item) ->
                                    $id = _getId _id, item
                                    if $id
                                        return node_by_id[$id]
                                    null

                                node_del = (node) ->
                                    $id = node.$id
                                    if $id
                                        delete node_by_id[$id]
                                    null

                                node_set = (item, node) ->
                                    $id = _getId _id, item
                                    node.$id = $id
                                    node_by_id[$id] = node
                                    null

                            else
                                if window.Map
                                    node_by_id = new Map()
                                    node_get = (item) ->
                                        node_by_id.get item

                                    node_del = (node) ->
                                        node_by_id.delete node.item
                                        null

                                    node_set = (item, node) ->
                                        node_by_id.set item, node
                                        null

                                else
                                    node_by_id = {}
                                    node_get = (item) ->
                                        $id = item.$alite_id
                                        if $id
                                            return node_by_id[$id]
                                        null

                                    node_del = (node) ->
                                        $id = node.$id
                                        if $id
                                            delete node_by_id[$id]
                                        null

                                    node_set = (item, node) ->
                                        $id = alight.utilits.getId()
                                        item.$alite_id = $id
                                        node.$id = $id
                                        node_by_id[$id] = node
                                        null

                    if not list or not list.length  # is it list?
                        list = []

                    if self.storeTo
                        scope.$setValue self.storeTo, list
                        scope.$scan
                            late: true

                    last_element = self.top_element

                    dom_inserts = []
                    nodes2 = []

                    # find removed
                    for node in nodes
                        node.active = false
                    for item, index in list
                        node = node_get item
                        if node
                            node.active = true

                    dom_removes = for node in nodes
                        if node.active
                            continue
                        if node.prev
                            node.prev.next = node.next
                        if node.next
                            node.next.prev = node.prev
                        node_del node
                        node.scope.$destroy()
                        node.element


                    applyList = []
                    # change positions and make new children
                    pid = null
                    child_scope
                    prev_node = null
                    for item, index in list
                        item_value = item
                        item = item or {}

                        node = node_get item

                        if node
                            self.updateChild node.scope, item, index, list
                            if node.prev is prev_node
                                # next loop
                                prev_node = node
                                last_element = node.element
                                node.active = true
                                nodes2.push node
                                continue

                            # make insert
                            node.prev = prev_node
                            if prev_node
                                prev_node.next = node
                            dom_inserts.push
                                element: node.element
                                after: if prev_node then prev_node.element else self.top_element
                            
                            # next loop
                            last_element = node.element
                            prev_node = node
                            node.active = true
                            nodes2.push node
                            continue

                        child_scope = self.makeChild item_value, index, list

                        element = f$.clone self.base_element
                        applyList.push [child_scope, element]
                        #alight.applyBindings child_scope, element, { skip_attr:env.attrName }

                        dom_inserts.push
                            element: element
                            after: last_element

                        node =
                            scope: child_scope
                            element: element
                            prev: prev_node
                            next: null
                            active: true
                            item: item

                        node_set item, node
                        if prev_node
                            next2 = prev_node.next
                            prev_node.next = node
                            node.next = next2
                            if next2
                                next2.prev = node
                        else if index is 0 and nodes[0]
                            next2 = nodes[0]
                            node.next = next2
                            next2.prev = node

                        # for next loop
                        prev_node = node
                        last_element = element
                        nodes2.push node

                    nodes = nodes2

                    self.rawUpdateDom dom_removes, dom_inserts

                    #applying
                    skippedAttrs = env.skippedAttr()
                    for it in applyList
                        alight.applyBindings it[0], it[1], { skip_attr:skippedAttrs }
                    null


alight.directives.bo.repeat =
    priority: 1000
    init: (element, exp, scope, env) ->
        self = alight.directives.al.repeat.init element, exp, scope, env
        self.start = ->
            self.prepare()
            self.parsExpression()
            self.prepareDom()
            self.watch =
                value: scope.$eval self.expression
            self.initUpdateDom()
        self
