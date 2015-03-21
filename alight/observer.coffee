
###
    observer = alight.observer.create()
    ob = observer.observe scope
    observer.deliver()
    observer.destroy()
    
    ob = observer.observe scope
    ob.watch key, callback
    ob.unwatch key, callback
    ob.rootEvent = fn
    ob.fire key
    ob.reobserve key
    ob.destroy()
###

do ->
    alight.observer = self = {}

    self.support = ->
        if typeof WeakMap isnt 'function'
            return false
        if typeof Object.observe isnt 'function'
            return false
        if typeof Symbol isnt 'function'
            return false
        true

    if not self.support()
        return

    isObjectOrArray = (d) ->
        if f$.isObject d
            return true
        f$.isArray d

    getId = do ->
        i = 0
        ->
            i++
            'n' + i

    $cbs = Symbol 'callbacks'
    $scope = Symbol 'scope'
    $path = Symbol 'path'
    $node = Symbol 'node'
    $isArray = Symbol 'isArray'

    ensureTree = (node, key, flag) ->
        wtree = node.wtree

        for k in key.split '.'
            wtree = wtree[k]
            if not wtree
                break

        if wtree
            __ensureTree node, wtree, key, flag

    __ensureTree = (node, wtree, path, flag) ->
        r = false
        for k of wtree
            if node.keywords[k]
                continue
            if __ensureTree node, wtree[k], "#{path}.#{k}", flag
                r = true

        if not r and wtree[$cbs].length
            ensureObserve node, path, flag
            return true
        false

    cleanTree = (node, tree, checkingScope) ->
        if checkingScope and checkingScope isnt tree[$scope]
            console.error 'Observe: fake scope'
        scope = tree[$scope]

        if f$.isArray scope
            tree[$isArray] = null
            Array.unobserve scope, node.observer.handler
        else
            Object.unobserve scope, node.observer.handler

        scopeTree = node.observer.treeByScope.get scope
        delete scopeTree[node.id]
        tree[$node] = null
        tree[$scope] = null
        tree[$path] = null
        for k, v of tree
            if node.keywords[k]
                continue
            if not f$.isObject v
                continue
            cleanTree node, tree[k]
        null


    ensureObserve = (node, key, flag) ->
        scope = node.scope
        tree = node.tree
        treeByScope = node.observer.treeByScope

        kList = key.split '.'

        path = ''
        i = 0
        len = kList.length
        while i < len
            k = kList[i++]

            if len is i  # i was incremented
                if not f$.isArray scope[k]
                    break
            else
                if not isObjectOrArray scope[k]
                    break

            if not tree[k]
                tree[k] = {}
            tree = tree[k]

            if path
                path += '.' + k
            else
                path = k
            scope = scope[k]

            # checks
            scopeTree = treeByScope.get scope
            if not scopeTree
                scopeTree = {}
                treeByScope.set scope, scopeTree

            #if scope[$tree]
            if scopeTree[node.id]
                continue
                #throw 'ERROR: scope has already observed'

            if tree[$scope]
                if flag is 'add'  # must be event is depricated
                    continue
                throw 'ERROR: tree has already got scope, why?'

            tree[$node] = node
            tree[$path] = path
            tree[$scope] = scope
            #scope[$tree] = tree
            scopeTree[node.id] = tree
            if f$.isArray scope
                tree[$isArray] = true
                Array.observe scope, node.observer.handler
            else
                Object.observe scope, node.observer.handler
        null


    Node = (observer, scope, keywords) ->
        if not f$.isObject scope
            throw 'Only objects can be observed'

        @.id = getId()
        @.active = true
        @.observer = observer
        @.rootEvent = null
        @.keywords = {}
        if keywords
            for k in keywords
                @.keywords[k] = true

        @.scope = scope
        @.wtree = {}  # store callbacks by keys
        @.tree = tree = {}   # scope, path, isArray

        observer.nodes.push @

        # observer root
        node = @
        scopeTree = observer.treeByScope.get scope
        if not scopeTree
            scopeTree = {}
            observer.treeByScope.set scope, scopeTree

        if scopeTree[node.id]
            throw 'ERROR: scope has already observed'

        if tree[$scope]
            throw 'ERROR: tree has already got scope, why?'

        tree[$node] = node
        tree[$path] = ''
        tree[$scope] = scope
        scopeTree[node.id] = tree
        Object.observe scope, node.observer.handler

        @

    Node::watch = (key, callback) ->
        if not @.active
            throw 'Inactive observer'
        t = @.wtree
        for k in key.split '.'
            if @.keywords[k]
                return  # keyword in path of key
            if not t[k]
                t[k] = {}
                t[k][$cbs] = []
            t = t[k]
            t[$cbs].push callback
        ensureTree @, key, 'watch'
        callback

    Node::unwatch = (key, callback) ->
        t = @.wtree
        for k in key.split '.'
            c = t[k]
            if not c
                continue
            i = c[$cbs].indexOf callback
            if i>= 0
                c[$cbs].splice i, 1
            t = c
        null

    Node::reobserve = (key) ->
        if @.tree[key]
            cleanTree @, @.tree[key]
        if isObjectOrArray @.scope[key]
            ensureTree @, key

    Node::fire = (key, value) ->
        t = @.wtree
        for k in key.split '.'
            t = t[k] or {}
        if t[$cbs]
            for cb in t[$cbs]
                cb value
        null

    Node::destroy = ->
        if not @.active
            throw 'Inactive observer'
        @.active = false
        cleanTree @, @.tree
        i = @.observer.nodes.indexOf @
        if i >= 0
            @.observer.nodes.splice i, 1


    Observer = ->
        observer = @
        @.nodes = []
        @.treeByScope = new WeakMap()  # store trees by scopes
        @.handler = (changes) ->
            for ch in changes
                scope = ch.object

                scopeTree = observer.treeByScope.get scope
                if not scopeTree
                    console.warn 'Why we are here?'
                    continue

                for _, tree of scopeTree
                    node = tree[$node]
                    if tree[$isArray]
                        node.fire tree[$path], null
                    else
                        key = ch.name
                        if node.keywords[key]
                            continue

                        value = scope[key]

                        if tree[$path]
                            keyPath = "#{tree[$path]}.#{key}"
                        else
                            keyPath = key

                        if ch.type is 'add'
                            if isObjectOrArray value
                                ensureTree node, keyPath, 'add'
                            node.fire keyPath, value
                        else if ch.type is 'update'
                            if tree[key] and isObjectOrArray ch.oldValue
                                cleanTree node, tree[key], ch.oldValue
                            if isObjectOrArray value
                                ensureTree node, keyPath
                            node.fire keyPath, value
                        else if ch.type is 'delete'
                            if isObjectOrArray ch.oldValue
                                cleanTree node, tree[key], ch.oldValue
                            node.fire keyPath, null
                        if tree is node.tree and node.rootEvent
                            node.rootEvent keyPath, value
            null
            
        @

    Observer::observe = (root, options) ->
        options = options or {}
        n = new Node @, root, options.keywords
        n

    Observer::deliver = ->
        Object.deliverChangeRecords @.handler
    Observer::destroy = ->
        for n in @.nodes.slice()
            n.destroy()
        null

    self.create = ->
        new Observer()
