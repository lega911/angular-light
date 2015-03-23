
###

root = alight.Scope()

Scope::$new
Scope::$watch
Scope::$destroy

# can be bindable
Scope::$compile
    Scope::$eval
    Scope::$getValue
    Scope::$setValue

# only for root
Scope::$scan
    Scope::$scanAsync

# other
Scope::$rebuildObserve



makeWatch = (scope, $system) ->
    (name, callback, options) ->
        baseWatch name, callback, options, scope, $system
###

alight.core = self = {}

self.makeRoot = (conf) ->
    conf = conf or {}

    root =
        nodeHead: null
        nodeTail: null
        private: {}
        watchers:    # $finishBindings, $finishScan, $any
            finishBinding: []
            finishScan: []
            any: []
        status: null

        scan_callbacks: []

        # helpers
        extraLoop: false
        finishBinding_lock: false
        lateScan: false

    if conf.useObserver
        root.obList = []  # contain fired watchers
        root.observer = null
        root.privateOb = null

    root


self.makeNode = (root, scope) ->
    node =
        # local
        scope: scope
        root: root
        children: []
        watchers: {}
        watchList: []
        destroy_callbacks: []

        lineActive: false
        prevSibling: null
        nextSibling: null

        #
        rwatchers:
            any: []
            finishScan: []

    if root.observer
        # local
        node.obFire = {}
        node.ob = null

    node


WA = (callback) ->
    @.cb = callback

watchAny = (node, key, callback) ->
    root = node.root

    wa = new WA callback

    node.rwatchers[key].push wa
    root.watchers[key].push wa

    return {
        stop: ->
            removeItem node.rwatchers[key], wa
            removeItem root.watchers[key], wa
    }


self.watch = (node, name, callback, option) ->
    root = node.root
    scope = node.scope

    if option.is_array  # compatibility with old version
        option.isArray = true
    if f$.isFunction name
        exp = name
        key = alight.utilits.getId()
        isFunction = true
    else
        isFunction = false
        exp = null
        name = name.trim()
        if name[0..1] is '::'
            name = name[2..]
            option.oneTime = true
        if option.private
            if option.oneTime or option.isArray or option.deep
                throw 'Conflict $watch option private'
            privateName = name
            name = '$system.root.private.' + name
        key = name
        if key is '$any'
            return watchAny node, 'any', callback
        if key is '$finishScan'
            return watchAny node, 'finishScan', callback
        if key is '$destroy'
            return node.destroy_callbacks.push callback
        if key is '$finishBinding'
            return root.watchers.finishBinding.push callback
        if option.deep
            key = 'd#' + key
        else if option.isArray
            key = 'a#' + key
        else
            key = 'v#' + key

    if alight.debug.watch
        console.log '$watch', name

    d = node.watchers[key]
    if d
        if not option.readOnly
            d.extraLoop = true
        returnValue = d.value
    else
        # create watch object
        if not isFunction
            # options for observer
            if option.watchText
                exp = option.watchText.fn
                ce =
                    isSimple: if option.watchText.simpleVariables then 2 else 0
                    simpleVariables: option.watchText.simpleVariables
            else
                ce = self.compile scope, name,
                    noBind: true
                    full: true
                exp = ce.fn
        returnValue = value = exp scope
        if option.deep
            value = alight.utilits.clone value
            option.isArray = false
        node.watchers[key] = d =
            isArray: Boolean option.isArray
            extraLoop: not option.readOnly
            deep: option.deep
            value: value
            callbacks: []
            exp: exp
            src: '' + name

        # observe?
        isObserved = false
        if root.observer
            if not isFunction and not option.oneTime and not option.deep
                if ce.isSimple and ce.simpleVariables.length
                    isObserved = true

                    if d.isArray
                        d.value = null
                    else
                        if ce.isSimple < 2
                            isObserved = false

                    if isObserved
                        d.isObserved = true

                        if option.private
                            if not sys.privateOb
                                sys.privateOb = rootSys.observer.observe sys.private,
                                    keywords: ['$system', '$ns', '$parent']
                            ob = sys.privateOb.watch privateName, ->
                                if sys.obFire[key]
                                    return
                                sys.obFire[key] = true
                                rootSys.obList.push [scope, d]
                        else
                            for variable in ce.simpleVariables
                                ob = sys.ob.watch variable, ->
                                    if sys.obFire[key]
                                        return
                                    sys.obFire[key] = true
                                    rootSys.obList.push [scope, d]

        if option.isArray and not isObserved
            if f$.isArray value
                d.value = value.slice()
            else
                d.value = null
            returnValue = d.value

        if not isObserved
            node.watchList.push d

            # insert scope into root-chain
            if not node.lineActive
                node.lineActive = true
                t = root.nodeTail
                if t
                    root.nodeTail = t.nextSibling = node
                    node.prevSibling = t
                else
                    root.nodeHead = root.nodeTail = node

    r =
        $: d
        value: returnValue

    if option.oneTime
        realCallback = callback
        callback = (value) ->
            if value is undefined
                return
            r.stop()
            realCallback value

    d.callbacks.push callback
    r.stop = ->
        i = d.callbacks.indexOf callback
        if i >= 0
            d.callbacks.splice i, 1
            if d.callbacks.length isnt 0
                return
            # remove watch
            delete node.watchers[key]
            i = node.watchList.indexOf d
            if i >= 0
                node.watchList.splice i, 1

    if option.init
        callback r.value

    r


self.compile = (scope, src_exp, cfg) ->
    cfg = cfg or {}
    # make hash
    resp = {}
    src_exp = src_exp.trim()
    if src_exp[0..1] is '::'
        src_exp = src_exp[2..]
        resp.oneTime = true

    if cfg.stringOrOneTime
        cfg.string = not resp.oneTime

    hash = src_exp + '#'
    hash += if cfg.no_return then '+' else '-'
    hash += if cfg.string then 's' else 'v'
    if cfg.input
        hash += cfg.input.join ','

    cr = alight.utilits.compile.expression src_exp,
        scope: scope
        hash: hash
        no_return: cfg.no_return
        string: cfg.string
        input: cfg.input
        rawExpression: cfg.rawExpression

    func = cr.fn
    filters = cr.filters

    resp.rawExpression = cr.rawExpression
    resp.isSimple = cr.isSimple
    resp.simpleVariables = cr.simpleVariables

    if filters and filters.length
        func = alight.utilits.filterBuilder scope, func, filters
        if cfg.string
            f1 = func
            func = ->
                __ = f1.apply this, arguments
                "" + (__ or (__ ? ''))

    if cfg.noBind
        resp.fn = func
    else
        if (cfg.input || []).length < 4
            resp.fn = ->
                try
                    func scope, arguments[0], arguments[1], arguments[2]
                catch e
                    alight.exceptionHandler e, 'Wrong in expression: ' + src_exp,
                        src: src_exp
                        cfg: cfg
        else
            resp.fn = ->
                try
                    a = [scope]
                    for i in arguments
                        a.push i
                    func.apply null, a
                catch e
                    alight.exceptionHandler e, 'Wrong in expression: ' + src_exp,
                        src: src_exp
                        cfg: cfg

    if cfg.full
        return resp
    resp.fn


get_time = do ->
    if window.performance
        return ->
            Math.floor performance.now()
    ->
        (new Date()).getTime()


notEqual = (a, b) ->
    if a is null or b is null
        return true
    ta = typeof a
    tb = typeof b
    if ta isnt tb
        return true
    if ta is 'object'
        if a.length isnt b.length
            return true
        for v, i in a
            if v isnt b[i]
                return true
    false


scan_core = (top, result) ->
    extraLoop = false
    extraLoopFlag = false
    changes = 0
    total = 0
    line = []
    queue = [top]
    while queue
        scope = queue[0]
        index = 1
        while scope
            sys = scope.$system
            total += sys.watchList.length
            for w in sys.watchList
                result.src = w.src
                last = w.value
                value = w.exp scope
                if last isnt value
                    mutated = false
                    if w.isArray
                        a0 = f$.isArray last
                        a1 = f$.isArray value
                        if a0 is a1
                            if a0
                                if notEqual last, value
                                    w.value = value.slice()
                                    mutated = true
                        else
                            mutated = true
                            if a1
                                w.value = value.slice()
                            else
                                w.value = null
                    else if w.deep
                        if not alight.utilits.equal last, value
                            mutated = true
                            w.value = alight.utilits.clone value
                    else
                        mutated = true
                        w.value = value

                    if mutated
                        mutated = false
                        changes++
                        for callback in w.callbacks.slice()
                            if callback.call(scope, value) isnt '$scanNoChanges'
                                extraLoopFlag = true
                        if extraLoopFlag and w.extraLoop
                            extraLoop = true
                    if alight.debug.scan > 1
                        console.log 'changed:', w.src

            if sys.children.length
                line.push sys.children
            scope = queue[index++]
        
        queue = line.shift()

    result.total = total
    result.obTotal = 0
    result.changes = changes
    result.extraLoop = extraLoop


scan_core2 = (root, result) ->
    extraLoop = false
    extraLoopFlag = false
    changes = 0
    total = 0
    obTotal = 0

    # observed
    if root.observer
        root.observer.deliver()
        for x in rootSys.obList
            scope = x[0]
            w = x[1]

            scope.$system.obFire = {}

            result.src = w.src
            last = w.value
            value = w.exp scope
            if last isnt value
                if not w.isArray
                    w.value = value
                changes++
                for callback in w.callbacks.slice()
                    if callback.call(scope, value) isnt '$scanNoChanges'
                        extraLoopFlag = true
                if extraLoopFlag and w.extraLoop
                    extraLoop = true

        obTotal += root.obList.length
        root.obList.length = 0

    node = root.nodeHead
    while node
        scope = node.scope

        # default watchers
        total += node.watchList.length
        for w in node.watchList
            result.src = w.src
            last = w.value
            value = w.exp scope
            if last isnt value
                mutated = false
                if w.isArray
                    a0 = f$.isArray last
                    a1 = f$.isArray value
                    if a0 is a1
                        if a0
                            if notEqual last, value
                                w.value = value.slice()
                                mutated = true
                    else
                        mutated = true
                        if a1
                            w.value = value.slice()
                        else
                            w.value = null
                else if w.deep
                    if not alight.utilits.equal last, value
                        mutated = true
                        w.value = alight.utilits.clone value
                else
                    mutated = true
                    w.value = value

                if mutated
                    mutated = false
                    changes++
                    for callback in w.callbacks.slice()
                        if callback.call(scope, value) isnt '$scanNoChanges'
                            extraLoopFlag = true
                    if extraLoopFlag and w.extraLoop
                        extraLoop = true
                if alight.debug.scan > 1
                    console.log 'changed:', w.src

        node = node.nextSibling

    result.total = total
    result.obTotal = obTotal
    result.changes = changes
    result.extraLoop = extraLoop


self.scan = (root, cfg) ->
    cfg = cfg or {}
    if cfg.callback
        root.scan_callbacks.push cfg.callback
    if cfg.late
        if root.lateScan
            return
        root.lateScan = true
        alight.nextTick ->
            if root.lateScan
                self.scan root
        return
    if root.status is 'scaning'
        root.extraLoop = true
        return
    root.lateScan = false
    root.status = 'scaning'
    # take scan_callbacks
    scan_callbacks = root.scan_callbacks.slice()
    root.scan_callbacks.length = 0


    if alight.debug.scan
        start = get_time()

    mainLoop = 10
    try
        result =
            total: 0
            obTotal: 0
            changes: 0
            extraLoop: false
            src: ''

        while mainLoop
            mainLoop--

            root.extraLoop = false

            scan_core2 root, result

            # call $any
            if result.changes
                for cb in root.watchers.any
                    cb()
            if not result.extraLoop and not root.extraLoop
                break
        if alight.debug.scan
            duration = get_time() - start
            console.log "$scan: (#{10-mainLoop}) #{result.total} + #{result.obTotal} / #{duration}ms"
    catch e
        alight.exceptionHandler e, '$scan, error in expression: ' + result.src,
            src: result.src
            result: result
    finally
        root.status = null
        for callback in scan_callbacks
            callback.call root
        for callback in root.watchers.finishScan
            callback()

    if mainLoop is 0
        throw 'Infinity loop detected'
