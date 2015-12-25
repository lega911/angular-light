
###
    al-repeat="item in list"
    "item in list"
    "item in list | filter"
    "item in list | filter track by trackExpression"
    "item in list track by $index"
    "item in list track by $id(item)"
    "item in list track by item.id"

    "(key, value) in object"
    "(key, value) in object orderBy:key:reverse"
    "(key, value) in object | filter orderBy:key,reverse"
###

alight.directives.al.repeat =
    priority: 1000
    restrict: 'AM'
    stopBinding: true
    init: (parentScope, element, exp, env) ->  # Change Detector
        CD = parentScope.$changeDetector
        self =
            start: ->
                self.parsExpression()
                self.prepareDom()
                self.buildUpdateDom()
                self.watchModel()
                self.makeChildConstructor()
                return

            parsExpression: ->
                s = exp.trim()

                if s[0] is '('
                    # object
                    self.objectMode = true
                    r = s.match /\((\w+),\s*(\w+)\)\s+in\s+(.+)\s+orderBy:(.+)\s*$/
                    if r
                        self.objectKey = r[1]
                        self.objectValue = r[2]
                        self.expression = r[3] + " | toArray:#{self.objectKey},#{self.objectValue} | orderBy:#{r[4]}"
                        self.nameOfKey = '$item'
                        self.trackExpression = '$item.' + self.objectKey
                    else
                        r = s.match /\((\w+),\s*(\w+)\)\s+in\s+(.+)\s*$/
                        if not r
                            throw 'Wrong repeat: ' + exp
                        self.objectKey = r[1]
                        self.objectValue = r[2]
                        self.expression = r[3] + " | toArray:#{self.objectKey},#{self.objectValue}"
                        self.nameOfKey = '$item'
                        self.trackExpression = '$item.' + self.objectKey
                else
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
                return

            watchModel: ->
                if self.objectMode
                    flags =
                        deep: true
                else
                    flags =
                        isArray: true
                self.watch = CD.watch self.expression, self.updateDom, flags
                return

            prepareDom: ->
                if element.nodeType is 8
                    self.top_element = element
                    self.element_list = element_list = []
                    el = element.nextSibling
                    while el
                        if el.nodeType is 8
                            t = el.nodeValue
                            t2 = t.trim().split(/\s+/)
                            if t2[0] is '/directive:' and t2[1] is 'al-repeat'
                                env.skipToElement = el
                                break
                        element_list.push el
                        el = el.nextSibling
                    for el in element_list
                        f$.remove el
                    null
                else
                    self.base_element = element
                    self.top_element = document.createComment " #{exp} "
                    f$.before element, self.top_element
                    f$.remove element
                return

            makeChildConstructor: ->
                ChildScope = ->
                    @.$root = CD.scope.$root or CD.scope
                    @
                ChildScope:: = CD.scope
                self.ChildScope = ChildScope
                return

            makeChild: (item, index, list) ->
                scope = new self.ChildScope()
                scope.$rootChangeDetector = childCD = CD.new scope
                self.updateChild childCD, item, index, list
                childCD

            updateChild: (childCD, item, index, list) ->
                scope = childCD.scope
                if self.objectMode
                    scope[self.objectKey] = item[self.objectKey]
                    scope[self.objectValue] = item[self.objectValue]
                else
                    scope[self.nameOfKey] = item
                scope.$index = index
                scope.$first = index is 0
                scope.$last = index is list.length-1
                return

            rawUpdateDom: (removes, inserts) ->
                for e in removes
                    f$.remove e
                for it in inserts
                    f$.after it.after, it.element
                return

            buildUpdateDom: ->
                self.updateDom = do ->
                    nodes = []
                    index = 0
                    fastBinding = false

                    if self.trackExpression is '$index'
                        node_by_id = {}
                        node_get = (item) ->
                            $id = index
                            node_by_id[$id] or null

                        node_del = (node) ->
                            $id = node.$id
                            `if($id != null) delete node_by_id[$id]`
                            return

                        node_set = (item, node) ->
                            $id = index
                            node.$id = $id
                            node_by_id[$id] = node
                            return
                    else
                        if self.trackExpression
                            node_by_id = {}
                            _getId = do ->
                                fn = CD.compile self.trackExpression,
                                    input: ['$id', self.nameOfKey]
                                (a, b) ->
                                    fn CD.scope, a, b
                            _id = (item) ->
                                id = item.$alite_id
                                if id
                                    return id
                                id = item.$alite_id = alight.utils.getId()
                                id

                            node_get = (item) ->
                                $id = _getId _id, item
                                `if($id != null) return node_by_id[$id]`
                                null

                            node_del = (node) ->
                                $id = node.$id
                                `if($id != null) delete node_by_id[$id]`
                                return

                            node_set = (item, node) ->
                                $id = _getId _id, item
                                node.$id = $id
                                node_by_id[$id] = node
                                return

                        else
                            if window.Map
                                node_by_id = new Map()
                                node_get = (item) ->
                                    node_by_id.get item

                                node_del = (node) ->
                                    node_by_id.delete node.item
                                    return

                                node_set = (item, node) ->
                                    node_by_id.set item, node
                                    return

                            else
                                node_by_id = {}
                                node_get = (item) ->
                                    if typeof item is 'object'
                                        $id = item.$alite_id
                                        if $id
                                            return node_by_id[$id]
                                    else
                                        return node_by_id[item] or null
                                    null

                                node_del = (node) ->
                                    $id = node.$id
                                    if node_by_id[$id]
                                        node.$id = null
                                        delete node_by_id[$id]
                                    return

                                node_set = (item, node) ->
                                    if typeof item is 'object'
                                        $id = alight.utils.getId()
                                        item.$alite_id = $id
                                        node.$id = $id
                                        node_by_id[$id] = node
                                    else
                                        node.$id = item
                                        node_by_id[item] = node
                                    return

                    generator = []
                    getResultList = (input) ->
                        t = typeof input
                        if t is 'object'
                            if input and input.length
                                return input
                        else
                            if t is 'number'
                                size = Math.floor input
                            else if t is 'string'
                                size = Math.floor input
                                if isNaN size
                                    return []
                            if size < generator.length
                                generator.length = size
                            else
                                while generator.length < size
                                    generator.push generator.length
                            return generator
                        return []

                    if self.element_list
                        (input) ->
                            list = getResultList input
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

                            dom_removes = []
                            for node in nodes
                                if node.active
                                    continue
                                if node.prev
                                    node.prev.next = node.next
                                if node.next
                                    node.next.prev = node.prev
                                node_del node
                                node.CD.destroy()
                                for el in node.element_list
                                    dom_removes.push el
                                node.next = null
                                node.prev = null
                                node.element_list = null

                            applyList = []
                            # change positions and make new children
                            pid = null
                            prev_node = null
                            prev_moved = false
                            elLast = self.element_list.length - 1
                            for item, index in list
                                item_value = item
                                node = node_get item

                                if node
                                    self.updateChild node.CD, item, index, list
                                    if node.prev is prev_node
                                        if prev_moved
                                            for el in node.element_list
                                                dom_inserts.push
                                                    element: el
                                                    after: last_element
                                                last_element = el
                                        # next loop
                                        prev_node = node
                                        last_element = node.element_list[elLast]
                                        node.active = true
                                        nodes2.push node
                                        continue

                                    # make insert
                                    node.prev = prev_node
                                    if prev_node
                                        prev_node.next = node
                                    for el in node.element_list
                                        dom_inserts.push
                                            element: el
                                            after: last_element
                                        last_element = el
                                    prev_moved = true

                                    # next loop
                                    prev_node = node
                                    node.active = true
                                    nodes2.push node
                                    continue

                                childCD = self.makeChild item_value, index, list

                                element_list = for bel in self.element_list
                                    el = bel.cloneNode true
                                    applyList.push
                                        cd: childCD
                                        el: el

                                    dom_inserts.push
                                        element: el
                                        after: last_element
                                    last_element = el

                                node =
                                    CD: childCD
                                    element_list: element_list
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
                                nodes2.push node

                            nodes = nodes2

                            self.rawUpdateDom dom_removes, dom_inserts
                            dom_removes.length = 0
                            dom_inserts.length = 0

                            #applying
                            skippedAttrs = env.skippedAttr()
                            for it in applyList
                                alight.bind it.cd, it.el,
                                    skip_attr: skippedAttrs
                            return
                    else
                        # method update for a single element
                        (input) ->
                            list = getResultList input
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

                            dom_removes = []
                            for node in nodes
                                if node.active
                                    continue
                                if node.prev
                                    node.prev.next = node.next
                                if node.next
                                    node.next.prev = node.prev
                                node_del node
                                node.CD.destroy()
                                dom_removes.push node.element
                                node.next = null
                                node.prev = null
                                node.element = null

                            applyList = []
                            # change positions and make new children
                            pid = null
                            prev_node = null
                            prev_moved = false
                            for item, index in list
                                item_value = item
                                node = node_get item

                                if node
                                    self.updateChild node.CD, item, index, list
                                    if node.prev is prev_node
                                        if prev_moved
                                            dom_inserts.push
                                                element: node.element
                                                after: prev_node.element

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
                                        after: last_element
                                    prev_moved = true

                                    # next loop
                                    last_element = node.element
                                    prev_node = node
                                    node.active = true
                                    nodes2.push node
                                    continue

                                childCD = self.makeChild item_value, index, list

                                element = self.base_element.cloneNode true
                                applyList.push
                                    cd: childCD
                                    el: element

                                dom_inserts.push
                                    element: element
                                    after: last_element

                                node =
                                    CD: childCD
                                    element: element
                                    prev: prev_node
                                    next: null
                                    active: true
                                    item: item
                                last_element = element

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
                                nodes2.push node

                            nodes = nodes2

                            self.rawUpdateDom dom_removes, dom_inserts
                            dom_removes.length = 0
                            dom_inserts.length = 0

                            #applying
                            skippedAttrs = env.skippedAttr()
                            for it in applyList
                                if fastBinding
                                    fastBinding.bind it.cd, it.el
                                else
                                    r = alight.bind it.cd, it.el,
                                        skip_attr: skippedAttrs
                                    if r.directive is 0 and r.hook is 0
                                        fastBinding = new alight.core.fastBinding self.base_element
                            return
