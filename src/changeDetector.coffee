
alight.ChangeDetector = (scope) ->
    root = new Root()

    cd = new ChangeDetector root, scope or {}
    root.topCD = cd
    cd


Root = () ->
    @.cdLine = []
    @.private = {}
    @.watchers =
        any: []
        finishBinding: []
        finishScan: []
        finishScanOnce: []
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
    if @.topCD
        @.topCD.destroy()


ChangeDetector = (root, scope) ->
    # local
    @.scope = scope
    @.root = root
    @.watchers = {}
    @.watchList = []
    @.destroy_callbacks = []

    @.parent = null
    @.children = []

    root.cdLine.push @

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

    removeItem root.cdLine, cd

    if cd.parent
        removeItem cd.parent.children, cd

    for child in cd.children.slice()
        child.destroy()

    for fn in cd.destroy_callbacks
        fn()

    cd.destroy_callbacks.length = 0
    cd.watchList.length = 0
    watchers = cd.watchers
    cd.watchers = {}
    # call watch.onStop
    for k, d of watchers
        if d.onStop.length
            for fn in d.onStop
                fn()

    for wa in cd.rwatchers.any
        removeItem root.watchers.any, wa
    cd.rwatchers.any.length = 0
    for wa in cd.rwatchers.finishScan
        removeItem root.watchers.finishScan, wa
    cd.rwatchers.finishScan.length = 0

    if root.topCD is cd
        root.topCD = null
        root.destroy()


makeFilterChain = do ->
    index = 1
    getId = ->
        'wf' + (index++)

    (cd, pe, baseCallback, option) ->
        root = cd.root

        # watchMode: simple, deep, array
        if option.isArray
            watchMode = 'array'
        else if option.deep
            watchMode = 'deep'
        else
            watchMode = 'simple'
        prevCallback = baseCallback
        rindex = pe.result.length - 1
        onStop = []
        while rindex > 0
            filterExp = pe.result[rindex--].trim()
            i = filterExp.indexOf ':'
            if i>0
                filterName = filterExp[..i-1]
                filterArg = filterExp[i+1..]
            else
                filterName = filterExp
                filterArg = null

            filterBuilder = alight.getFilter filterName, cd, filterArg

            filter = filterBuilder filterArg, cd,
                setValue: prevCallback

            if f$.isFunction filter
                prevCallback = do (filter, prevCallback) ->
                    (value) ->
                        prevCallback filter value
            else
                if filter.watchMode
                    watchMode = filter.watchMode
                prevCallback = filter.onChange
                if filter.onStop
                    onStop.push filter.onStop

        watchOptions =
            init: option.init
            oneTime: option.oneTime
            onStop: ->
                for fn in onStop
                    fn()
                onStop.length = 0
        if watchMode is 'array'
            watchOptions.isArray = true
        else if watchMode is 'deep'
            watchOptions.deep = true
        w = cd.watch pe.expression, prevCallback, watchOptions

        w.value = undefined
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
        init
        onStop

        private
        watchText



###

ChangeDetector::watch = (name, callback, option) ->
    option = option or {}
    if option is true
        option =
            isArray: true

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
        if option.private
            throw 'private mode is depricated'
            if option.oneTime or option.isArray or option.deep
                throw 'Conflict $watch option private'
            privateName = name
            name = 'root.private.' + name
        key = name
        if key is '$any'
            return watchAny cd, 'any', callback
        if key is '$finishScan'
            return watchAny cd, 'finishScan', callback
        if key is '$finishScanOnce'
            return root.watchers.finishScanOnce.push callback
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

    d = cd.watchers[key]
    if d
        if not option.readOnly
            d.extraLoop = true
        returnValue = d.value
        exp = d.exp
    else
        # create watch object
        isStatic = false
        if not isFunction
            if option.watchText
                exp = option.watchText.fn
            else
                pe = alight.utils.parsExpression name
                if pe.result.length > 1  # has filters
                    return makeFilterChain cd, pe, callback, option
                ce = alight.utils.compile.expression(name)
                isStatic = ce.isSimple and ce.simpleVariables.length is 0 and not option.isArray
                exp = ce.fn
        returnValue = value = exp scope
        if option.deep
            value = alight.utils.clone value
            option.isArray = false
        d =
            isStatic: isStatic
            isArray: Boolean option.isArray
            extraLoop: not option.readOnly
            deep: option.deep
            value: value
            callbacks: []
            exp: exp
            src: '' + name
            onStop: []

        if option.isArray
            if f$.isArray value
                d.value = value.slice()
            else
                d.value = undefined
            returnValue = d.value

        if not isStatic
            cd.watchers[key] = d
            cd.watchList.push d

    r =
        $: d
        value: returnValue
        fire: ->
            if d.isArray
                callback exp scope
            else
                callback d.value

    if option.oneTime
        realCallback = callback
        callback = (value) ->
            if value is undefined
                return
            r.stop()
            realCallback value

    if option.onStop
        d.onStop.push option.onStop

    d.callbacks.push callback
    r.stop = ->
        removeItem d.callbacks, callback
        if d.callbacks.length isnt 0
            return
        # remove watch
        if not d.isStatic
            delete cd.watchers[key]
            removeItem cd.watchList, d
        if option.onStop
            option.onStop()

    if option.init
        callback r.value

    r


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


scanCore = (root, result) ->
    extraLoop = false
    changes = 0
    total = 0

    for cd in root.cdLine.slice()
        scope = cd.scope

        # default watchers
        total += cd.watchList.length
        for w in cd.watchList.slice()
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
                    if not alight.utils.equal last, value
                        mutated = true
                        w.value = alight.utils.clone value
                else
                    mutated = true
                    w.value = value

                if mutated
                    mutated = false
                    changes++
                    extraLoopFlag = false
                    for callback in w.callbacks.slice()
                        if callback.call(scope, value) isnt '$scanNoChanges'
                            extraLoopFlag = true
                    if extraLoopFlag and w.extraLoop
                        extraLoop = true
                if alight.debug.scan > 1
                    console.log 'changed:', w.src

    result.total = total
    result.changes = changes
    result.extraLoop = extraLoop


Root::scan = (cfg) ->
    root = @
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
                root.scan()
        return
    if root.status is 'scaning'
        root.extraLoop = true
        return
    root.lateScan = false
    root.status = 'scaning'
    # take finishScanOnce
    finishScanOnce = root.watchers.finishScanOnce.slice()
    root.watchers.finishScanOnce.length = 0


    if alight.debug.scan
        start = get_time()

    mainLoop = 10
    try
        result =
            total: 0
            changes: 0
            extraLoop: false
            src: ''

        while mainLoop
            mainLoop--

            root.extraLoop = false

            scanCore root, result

            # call $any
            if result.changes
                for cb in root.watchers.any
                    cb()
            if not result.extraLoop and not root.extraLoop
                break
        if alight.debug.scan
            duration = get_time() - start
            console.log "$scan: loops: (#{10-mainLoop}), last-loop changes: #{result.changes}, watches: #{result.total} / #{duration}ms"
    catch e
        alight.exceptionHandler e, '$scan, error in expression: ' + result.src,
            src: result.src
            result: result
    finally
        root.status = null
        for callback in root.watchers.finishScan
            callback()
        for callback in finishScanOnce
            callback.call root

    if mainLoop is 0
        throw 'Infinity loop detected'

    result


# redirects
alight.core.ChangeDetector = ChangeDetector

ChangeDetector::compile = (expression, option) ->
    alight.utils.compile.expression(expression, option).fn

ChangeDetector::scan = (option) ->
    @.root.scan option

ChangeDetector::setValue = (name, value) ->
    cd = @
    fn = cd.compile name + ' = $value',
        input: ['$value']
        no_return: true
    fn cd.scope, value

ChangeDetector::eval = (exp) ->
    fn = @.compile exp
    fn @.scope

ChangeDetector::getValue = (name) ->
    @.$eval name
