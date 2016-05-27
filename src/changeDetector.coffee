
alight.ChangeDetector = (scope) ->
    root = new Root()

    cd = new ChangeDetector root, scope or {}
    root.topCD = cd
    cd


Root = () ->
    @.watchers =
        any: []
        finishBinding: []
        finishScan: []
        finishScanOnce: []
        onScanOnce: []
    @.status = null

    # helpers
    @.extraLoop = false
    @.finishBinding_lock = false
    @.lateScan = false
    @.topCD = null

    @


Root::destroy = ->
    @.watchers.any.length = 0
    @.watchers.finishBinding.length = 0
    @.watchers.finishScan.length = 0
    @.watchers.finishScanOnce.length = 0
    @.watchers.onScanOnce.length = 0
    if @.topCD
        @.topCD.destroy()


ChangeDetector = (root, scope) ->
    @.scope = scope
    @.root = root
    @.watchList = []
    @.destroy_callbacks = []

    @.parent = null
    @.children = []

    #
    @.rwatchers =
        any: []
        finishScan: []
    @


ChangeDetector::new = (scope) ->
    parent = @
    cd = new ChangeDetector parent.root, scope or parent.scope
    cd.parent = parent
    parent.children.push cd

    cd


ChangeDetector::destroy = ->
    cd = @
    root = cd.root
    cd.scope = null

    if cd.parent
        removeItem cd.parent.children, cd

    for child in cd.children.slice()
        child.destroy()

    for fn in cd.destroy_callbacks
        fn()

    cd.destroy_callbacks.length = 0
    for d in cd.watchList
        if d.onStop
            d.onStop()
    cd.watchList.length = 0

    for wa in cd.rwatchers.any
        removeItem root.watchers.any, wa
    cd.rwatchers.any.length = 0
    for wa in cd.rwatchers.finishScan
        removeItem root.watchers.finishScan, wa
    cd.rwatchers.finishScan.length = 0

    if root.topCD is cd
        root.topCD = null
        root.destroy()
    return


getFilter = (name, cd) ->
    error = false
    scope = cd.scope
    if scope.$ns and scope.$ns.filters
        filter = scope.$ns.filters[name]
        if not filter and not scope.$ns.inheritGlobal
            error = true
    if not filter and not error
        filter = alight.filters[name]
    if not filter
        throw 'Filter not found: ' + name
    filter


makeFilterChain = do ->
    index = 1
    getId = ->
        'wf' + (index++)

    (cd, ce, baseCallback, option) ->
        root = cd.root

        # watchMode: simple, deep, array
        if option.isArray
            watchMode = 'array'
        else if option.deep
            watchMode = 'deep'
        else
            watchMode = 'simple'
        prevCallback = baseCallback
        rindex = ce.filters.length
        onStop = []
        while rindex > 0
            filterExp = ce.filters[--rindex].trim()
            i = filterExp.indexOf ':'
            if i>0
                filterName = filterExp[..i-1]
                filterArg = filterExp[i+1..]
            else
                filterName = filterExp
                filterArg = null

            filterObject = getFilter filterName, cd
            if Array.isArray(filterObject)
                cd.scope.$changeDetector = cd
                filter = filterObject[0] filterArg, cd.scope,
                    setValue: prevCallback
                    changeDetector: cd
                cd.scope.$changeDetector = null

                if filter.watchMode
                    watchMode = filter.watchMode

                if filter.onStop
                    onStop.push filter.onStop

                if filter.onChange
                    prevCallback = filter.onChange
            else if Object.keys(filterObject::).length
                # class
                cd.scope.$changeDetector = cd
                filter = new filterObject filterArg, cd.scope,
                    setValue: prevCallback
                    changeDetector: cd
                cd.scope.$changeDetector = null
                filter.setValue = prevCallback

                if filter.watchMode
                    watchMode = filter.watchMode

                if filter.onStop
                    onStop.push filter.onStop.bind filter

                if filter.onChange
                    prevCallback = filter.onChange.bind filter
            else
                prevCallback = do (filter=filterObject, prevCallback, filterArg, cd) ->
                    (value) ->
                        prevCallback filter value, filterArg, cd.scope

        watchOptions =
            oneTime: option.oneTime
            onStop: ->
                for fn in onStop
                    fn()
                onStop.length = 0
        if watchMode is 'array'
            watchOptions.isArray = true
        else if watchMode is 'deep'
            watchOptions.deep = true
        w = cd.watch ce.expression, prevCallback, watchOptions
        w


WA = (callback) ->
    @.cb = callback

watchAny = (cd, key, callback) ->
    root = cd.root

    wa = new WA callback

    cd.rwatchers[key].push wa
    root.watchers[key].push wa

    return {
        stop: ->
            removeItem cd.rwatchers[key], wa
            removeItem root.watchers[key], wa
    }


###

    option:
        isArray
        readOnly
        oneTime
        deep
        onStop

        watchText



###

watchInitValue = ->

ChangeDetector::watch = (name, callback, option) ->
    option = option or {}
    if option is true
        option =
            isArray: true

    if option.init
        console.warn 'watch.init is depticated'

    cd = @
    root = cd.root
    scope = cd.scope

    if f$.isFunction name
        exp = name
        key = alight.utils.getId()
        isFunction = true
    else
        isFunction = false
        exp = null
        name = name.trim()
        if name[0..1] is '::'
            name = name[2..]
            option.oneTime = true
        key = name
        if key is '$any'
            return watchAny cd, 'any', callback
        if key is '$finishScan'
            return watchAny cd, 'finishScan', callback
        if key is '$finishScanOnce'
            return root.watchers.finishScanOnce.push callback
        if key is '$onScanOnce'
            return root.watchers.onScanOnce.push callback
        if key is '$destroy'
            return cd.destroy_callbacks.push callback
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

    # create watch object
    isStatic = false
    if not isFunction
        if option.watchText
            exp = option.watchText.fn
        else
            ce = alight.utils.compile.expression(name)
            if ce.filters
                return makeFilterChain cd, ce, callback, option
            isStatic = ce.isSimple and ce.simpleVariables.length is 0
            exp = ce.fn

    if option.deep
        option.isArray = false
    d =
        isStatic: isStatic
        isArray: Boolean option.isArray
        extraLoop: not option.readOnly
        deep: if option.deep is true then 10 else option.deep
        value: watchInitValue
        callback: callback
        exp: exp
        src: '' + name
        onStop: option.onStop or null
        el: option.element or null
        ea: option.elementAttr or null

    if isStatic
        cd.watch '$onScanOnce', ->
            execWatchObject scope, d, d.exp scope
    else
        cd.watchList.push d

    r =
        $: d
        stop: ->
            if d.isStatic
                return
            removeItem cd.watchList, d
            if option.onStop
                option.onStop()
        refresh: ->
            value = d.exp scope
            if value and d.deep
                d.value = alight.utils.clone value, d.deep
            else if value and d.isArray
                d.value = value.slice()
            else
                d.value = value

    if option.oneTime
        d.callback = (value) ->
            if value is undefined
                return
            r.stop()
            callback value
    r


ChangeDetector::watchGroup = (keys, callback) ->
    cd = @
    if not callback and f$.isFunction keys
        callback = keys
        keys = null

    planned = false
    group = ->
        if planned
            return
        planned = true
        cd.watch '$onScanOnce', ->
            planned = false
            callback()
    if keys
        for key in keys
            cd.watch key, group
    group


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


execWatchObject = (scope, w, value) ->
    if w.el
        if w.ea
            w.el.setAttribute w.ea, value
        else
            w.el.nodeValue = value
    else
        w.callback.call scope, value
    return


scanCore = (topCD, result) ->
    root = topCD.root
    extraLoop = false
    changes = 0
    total = 0

    if not topCD
        return

    queue = []
    index = 0
    cd = topCD
    while cd
        scope = result.scope = cd.scope

        # default watchers
        total += cd.watchList.length
        for w in cd.watchList.slice()
            result.src = w.src
            result.element = w.el
            last = w.value
            value = w.exp scope
            if last isnt value
                mutated = false
                if w.isArray
                    a0 = Array.isArray last
                    a1 = Array.isArray value
                    if a0 is a1
                        if a0
                            if notEqual last, value
                                mutated = true
                                w.value = value.slice()
                        else
                            mutated = true
                            w.value = value
                    else
                        mutated = true
                        if a1
                            w.value = value.slice()
                        else
                            w.value = value
                else if w.deep
                    if not alight.utils.equal last, value, w.deep
                        mutated = true
                        w.value = alight.utils.clone value, w.deep
                else
                    mutated = true
                    w.value = value

                if mutated
                    mutated = false
                    changes++

                    # fire
                    if w.el
                        if w.ea
                            w.el.setAttribute w.ea, value
                        else
                            w.el.nodeValue = value
                    else
                        if last is watchInitValue
                            last = undefined
                        if w.callback.call(scope, value, last) isnt '$scanNoChanges'
                            if w.extraLoop
                                extraLoop = true
                if alight.debug.scan > 1
                    console.log 'changed:', w.src
        queue.push.apply queue, cd.children
        cd = queue[index++]

    result.total = total
    result.changes = changes
    result.extraLoop = extraLoop

    result.scope = null
    result.src = ''
    result.element = null
    return


ChangeDetector::digest = ->
    root = @.root
    mainLoop = 10
    totalChanges = 0

    if alight.debug.scan
        start = get_time()

    try
        result =
            total: 0
            changes: 0
            extraLoop: false
            src: ''
            scope: null
            element: null

        while mainLoop
            mainLoop--
            root.extraLoop = false

            # take onScanOnce
            if root.watchers.onScanOnce.length
                onScanOnce = root.watchers.onScanOnce.slice()
                root.watchers.onScanOnce.length = 0
                for callback in onScanOnce
                    callback.call root

            scanCore @, result
            totalChanges += result.changes

            if not result.extraLoop and not root.extraLoop
                break
        if alight.debug.scan
            duration = get_time() - start
            console.log "$scan: loops: (#{10-mainLoop}), last-loop changes: #{result.changes}, watches: #{result.total} / #{duration}ms"
    catch e
        alight.exceptionHandler e, '$scan, error in expression: ' + result.src,
            src: result.src
            scope: result.scope
            element: result.element
            result: result
    result.mainLoop = mainLoop
    result.totalChanges = totalChanges
    result


ChangeDetector::scan = (cfg) ->
    root = @.root
    cfg = cfg or {}
    if f$.isFunction cfg
        cfg =
            callback: cfg
    if cfg.callback
        root.watchers.finishScanOnce.push cfg.callback
    if cfg.late
        if root.lateScan
            return
        root.lateScan = true
        alight.nextTick ->
            if root.lateScan
                root.topCD.scan()
        return
    if root.status is 'scaning'
        root.extraLoop = true
        return
    root.lateScan = false
    root.status = 'scaning'

    if root.topCD
        result = root.topCD.digest()
    else
        result = {}

    if result.totalChanges
        for cb in root.watchers.any
            cb()

    root.status = null
    for callback in root.watchers.finishScan
        callback()

    # take finishScanOnce
    finishScanOnce = root.watchers.finishScanOnce.slice()
    root.watchers.finishScanOnce.length = 0
    for callback in finishScanOnce
        callback.call root

    if result.mainLoop is 0
        throw 'Infinity loop detected'

    result


# redirects
alight.core.ChangeDetector = ChangeDetector

ChangeDetector::compile = (expression, option) ->
    alight.utils.compile.expression(expression, option).fn

ChangeDetector::setValue = (name, value) ->
    cd = @
    fn = cd.compile name + ' = $value',
        input: ['$value']
        no_return: true
    try
        fn cd.scope, value
    catch e
        msg = "can't set variable: #{name}"
        if alight.debug.parser
            console.warn msg
        if (''+e).indexOf('TypeError') >= 0
            rx = name.match(/^([\w\d\.]+)\.[\w\d]+$/)
            if rx and rx[1]
                # try to make a path
                scope = cd.scope
                for key in rx[1].split '.'
                    if scope[key] is undefined
                        scope[key] = {}
                    scope = scope[key]
                try
                    fn cd.scope, value
                    return
                catch

        alight.exceptionHandler e, msg,
            name: name
            value: value

ChangeDetector::eval = (exp) ->
    fn = @.compile exp
    fn @.scope

ChangeDetector::getValue = (name) ->
    @.eval name
