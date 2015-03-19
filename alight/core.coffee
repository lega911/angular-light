# Angular light
# version: 0.8.15 / 2015-03-19

# init
alight.version = '0.8.15'
alight.debug =
    useObserver: false
    observer: 0
    scan: 0
    directive: false
    watch: false
    watchText: false
    parser: false
alight.controllers = {}
alight.filters = {}
alight.utilits = {}
alight.directives =
    al: {}
    bo: {}
    ctrl: {}
alight.text = {}
alight.apps = {}


alight.directivePreprocessor = directivePreprocessor = (attrName, args) ->
    # html prefix data
    if attrName[0..4] is 'data-'
        name = attrName[5..]
    else
        name = attrName

    j = name.indexOf '-'
    if j < 0
        return { noNs: true }

    ns = name.substring 0, j
    name = name.substring(j+1).replace /(-\w)/g, (m) ->
        m.substring(1).toUpperCase()

    if args.scope.$ns and args.scope.$ns.directives
        path = args.scope.$ns.directives[ns]
    else        
        path = alight.directives[ns]
    if not path
        return { noNs: true }

    raw = path[name]
    if not raw
        return { noDirective: true }

    dir = {}
    if f$.isFunction raw
        dir.init = raw
    else if f$.isObject raw
        for k, v of raw
            dir[k] = v
    else throw 'Wrong directive: ' + ns + '.' + name
    dir.priority = raw.priority or 0
    dir.restrict = raw.restrict or 'A'

    if dir.restrict.indexOf(args.attr_type) < 0
        throw 'Directive has wrong binding (attribute/element): ' + name

    dir.$init = (element, expression, scope, env) ->

        doProcess = ->
            l = dscope.procLine
            for dp, i in l
                dp.fn.call dscope
                if dscope.isDeferred
                    dscope.procLine = l[i+1..]
                    break
            null

        dscope =
            element: element
            expression: expression
            scope: scope
            env: env
            ns: ns
            name: name
            args: args
            directive: dir
            result: {}
            
            isDeferred: false
            procLine: directivePreprocessor.ext
            makeDeferred: ->
                dscope.isDeferred = true
                dscope.result.owner = true  # stop binding
                dscope.doBinding = true     # continue binding

                ->
                    dscope.isDeferred = false
                    doProcess()

        doProcess()        
        dscope.result
    dir


do ->
    directivePreprocessor.ext = ext = []

    ext.push
        code: 'init'
        fn: ->
            if @.directive.init
                @.result = @.directive.init(@.element, @.expression, @.scope, @.env) or {}
            if not f$.isObject(@.result)
                @.result = {}

    ext.push
        code: 'templateUrl'
        fn: ->
            ds = @
            if @.directive.templateUrl
                callback = @.makeDeferred()
                f$.ajax
                    cache: true
                    url: @.directive.templateUrl
                    success: (html) ->
                        ds.directive.template = html
                        callback()
                    error: callback

    ext.push
        code: 'template'
        fn: ->
            if @.directive.template
                if @.element.nodeType is 1
                    f$.html @.element, @.directive.template
                else if @.element.nodeType is 8
                    el = document.createElement 'p'
                    el.innerHTML = @.directive.template.trimLeft()
                    el = el.firstChild
                    f$.after @.element, el
                    @.element = el
                    if not @.directive.scope
                        @.directive.scope = true

    ext.push
        code: 'scope'
        fn: ->
            if @.directive.scope
                parentScope = @.scope
                @.scope = parentScope.$new(@.directive.scope is 'isolate')
                @.result.owner = true
                @.doBinding = true

    ext.push
        code: 'link'
        fn: ->
            if @.directive.link
                @.directive.link(@.element, @.expression, @.scope, @.env)

    ext.push
        code: 'scopeBinding'
        fn: ->
            if @.doBinding
                alight.applyBindings @.scope, @.element, { skip_attr:@.env.skippedAttr() }


testDirective = do ->
    addAttr = (attrName, args, base) ->
        if args.attr_type is 'A'
            attr = base or {}
            attr.priority = -5
            attr.is_attr = true
            attr.name = attrName
            attr.attrName = attrName
            attr.element = args.element
            args.list.push attr

    (attrName, args) ->
        if args.skip_attr.indexOf(attrName) >= 0
            return addAttr attrName, args, { skip:true }

        directive = alight.directivePreprocessor attrName, args
        if directive.noNs
            return addAttr attrName, args
        if directive.noDirective
            return addAttr attrName, args, { noDirective:true }

        args.list.push
            name: attrName
            directive: directive
            priority: directive.priority
            attrName: attrName


sortByPriority = (a, b) ->
    if a.priority == b.priority
        return 0
    if a.priority > b.priority
        return -1
    else
        return 1


attrBinding = (element, value, scope, attrName) ->
    text = value
    if text.indexOf(alight.utilits.pars_start_tag) < 0
        return

    setter = (result) ->
        f$.attr element, attrName, result
    w = scope.$watchText text, setter,
        readOnly: true
    setter w.value


textBinding = (scope, node) ->
    text = node.data
    if text.indexOf(alight.utilits.pars_start_tag) < 0
        return
    setter = (result) ->
        node.nodeValue = result
    w = scope.$watchText text, setter,
        readOnly: true
    setter w.value


bindComment = (scope, element) ->
    text = element.nodeValue.trimLeft()
    if text[0..9] isnt 'directive:'
        return
    text = text[10..].trimLeft()
    i = text.indexOf ' '
    if i >= 0
        dirName = text[0..i-1]
        value = text[i+1..]
    else
        dirName = text
        value = ''

    args =
        list: list = []
        element: element
        attr_type: 'M'
        scope: scope
        skip_attr: []
    
    testDirective dirName, args

    d = list[0]
    if d.noDirective
        throw "Directive not found: #{d.name}"

    directive = d.directive
    env =
        element: element
        attrName: dirName
        attributes: []
        skippedAttr: ->
            []
    if alight.debug.directive
        console.log 'bind', d.attrName, value, d
    try
        result = directive.$init element, value, scope, env
        if result and result.start
            result.start()
    catch e
        alight.exceptionHandler e, 'Error in directive: ' + d.name,
            value: value
            env: env
            scope: scope
            element: element


process = do ->
    takeAttr = (name, skip) ->
        if arguments.length is 1
            skip = true
        for attr in @.attributes
            if attr.attrName isnt name
                continue
            if skip
                attr.skip = true
            value = f$.attr @.element, name
            return value or true

    skippedAttr = ->
        for attr in @.attributes
            if not attr.skip
                continue
            attr.attrName

    (scope, element, config) ->
        config = config || {}
        skip_children = false
        skip_attr = config.skip_attr or []
        if not (skip_attr instanceof Array)
            skip_attr = [skip_attr]

        if !config.skip_top
            args =
                list: list = []
                element: element
                skip_attr: skip_attr
                attr_type: 'E'
                scope: scope
            
            attrName = element.nodeName.toLowerCase()
            testDirective attrName, args

            args.attr_type = 'A'
            attrs = f$.getAttributes element
            for attrName, attr_value of attrs
                testDirective attrName, args

            # sort by priority
            list = list.sort sortByPriority

            for d in list
                if d.skip
                    continue
                if d.noDirective
                    throw "Directive not found: #{d.name}"
                d.skip = true
                value = f$.attr element, d.attrName
                if d.is_attr
                    attrBinding element, value, scope, d.attrName
                else
                    directive = d.directive
                    env =
                        element: element
                        attrName: d.attrName
                        attributes: list
                        takeAttr: takeAttr
                        skippedAttr: skippedAttr
                    if alight.debug.directive
                        console.log 'bind', d.attrName, value, d
                    try
                        result = directive.$init element, value, scope, env
                        if result and result.start
                            result.start()
                    catch e
                        alight.exceptionHandler e, 'Error in directive: ' + d.attrName,
                            value: value
                            env: env
                            scope: scope
                            element: element

                    if result and result.owner
                        skip_children = true
                        break

        if !skip_children
            # text bindings
            for node in f$.childNodes element
                if not node
                    continue
                fn = nodeTypeBind[node.nodeType]
                if fn
                    fn scope, node
        null

nodeTypeBind =
    1: process      # element
    3: textBinding  # text
    8: bindComment  # comment


Scope = (conf) ->
    `
    if(this instanceof Scope) return this;

    conf = conf || {};
    var scope;
    if(conf.prototype) {
        var Parent = function() {};
        Parent.prototype = conf.prototype;
        var parent = new Parent();
        var proto = Scope.prototype;
        for(var k in proto)
            if(proto.hasOwnProperty(k)) parent[k] = proto[k];

        var NScope = function() {};
        NScope.prototype = parent;
        scope = new NScope();
    } else scope = new Scope();
    `
    scope.$system = sys =
        watches: {}
        watchList: []
        watchAny: []
        watchAnyAll: []
        watchFinishScan: []
        watchFinishScanAll: []
        root: scope
        children: []
        scan_callbacks: []
        destroy_callbacks: []
        finishBinding_callbacks: []
        finishBinding_lock: false
        private: {}

    if typeof(conf.useObserver) is 'boolean'
        sys.useObserver = conf.useObserver
    else
        sys.useObserver = alight.debug.useObserver

    if sys.useObserver
        sys.useObserver = !!Object.observe

    if sys.useObserver
        # chain for active scopes
        sys.lineHead = null
        sys.lineTail = null
        sys.lineActive = false
        sys.prevSibling = null
        sys.nextSibling = null

        sys.obList = []  # contain fired watchers
        sys.obFire = {}
        sys.ob = ob = alight.observer.observe scope,
            rootEvent: (key, value) ->
                if alight.debug.observer
                    console.warn 'Reobserve', key
                for child in scope.$system.children
                    child.$$rebuildObserve key, value
                null
        sys.observers = [ob]  # list of all observers
    scope

alight.Scope = Scope


Scope::$$rebuildObserve = (key, value) ->
    scope = @
    alight.observer.reobserve scope.$system.ob, key
    for child in scope.$system.children
        child.$$rebuildObserve key, value
    alight.observer.fire scope.$system.ob, key, value


Scope::$new = (isolate) ->
    scope = this

    if isolate
        child = alight.Scope()
    else
        if not scope.$system.ChildScope
            scope.$system.ChildScope = ->
                root = scope.$system.root
                @.$system = sys =
                    watches: {}
                    watchList: []
                    watchAny: []
                    watchFinishScan: []
                    root: root
                    children: []
                    destroy_callbacks: []
                    private: {}
                @.$parent = null
                if root.$system.useObserver
                    cscope = @
                    sys.prevSibling = null
                    sys.nextSibling = null
                    sys.lineActive = false
                    sys.obFire = {}
                    sys.ob = ob = alight.observer.observe @,
                        rootEvent: (key, value) ->
                            if alight.debug.observer
                                console.warn 'Reobserve', key
                            for i in cscope.$system.children
                                i.$$rebuildObserve key, value
                            null
                    root.$system.observers.push ob
                @

            scope.$system.ChildScope:: = scope
        child = new scope.$system.ChildScope()

    child.$parent = scope
    scope.$system.children.push child
    child


###
$watch
    name:
        expression or function
        $any
        $destroy
        $finishBinding
        $finishScan
    callback:
        function
    option:
        isArray (is_array)
        readOnly
        init
        deep

###

injectToRootLine = (scope) ->
    sys = scope.$system
    if sys.lineActive
        return
    rootSys = sys.root.$system
    sys.lineActive = true
    t = rootSys.lineTail
    if t
        rootSys.lineTail = t.$system.nextSibling = scope
        sys.prevSibling = t
    else
        rootSys.lineHead = rootSys.lineTail = scope


do ->
    WA = (callback) ->
        @.cb = callback

    watchAny = (scope, lkey, rkey, callback) ->
        sys = scope.$system
        rootSys = sys.root.$system

        wa = new WA callback

        sys[lkey].push wa
        rootSys[rkey].push wa

        return {
            stop: ->
                l = sys[lkey]
                i = l.indexOf wa
                if i >= 0
                    l.splice i, 1

                l = rootSys[rkey]
                i = l.indexOf wa
                if i >= 0
                    l.splice i, 1
        }


    Scope::$watch = (name, callback, option) ->
        scope = @
        sys = scope.$system
        rootSys = sys.root.$system
        if option is true
            option =
                isArray: true
        else if not option
            option = {}
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
            key = name
            if key is '$any'
                return watchAny scope, 'watchAny', 'watchAnyAll', callback
            if key is '$finishScan'
                return watchAny scope, 'watchFinishScan', 'watchFinishScanAll', callback
            if key is '$destroy'
                return sys.destroy_callbacks.push callback
            if key is '$finishBinding'
                return rootSys.finishBinding_callbacks.push callback
            if option.deep
                key = 'd#' + key
            else if option.isArray
                key = 'a#' + key
            else
                key = 'v#' + key

        if alight.debug.watch
            console.log '$watch', name

        d = sys.watches[key]
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
                    ce = scope.$compile name,
                        noBind: true
                        full: true
                    exp = ce.fn
            returnValue = value = exp scope
            if option.deep
                value = alight.utilits.clone value
                option.isArray = false
            sys.watches[key] = d =
                isArray: Boolean option.isArray
                extraLoop: not option.readOnly
                deep: option.deep
                value: value
                callbacks: []
                exp: exp
                src: '' + name

            # observe?
            isObserved = false
            if rootSys.useObserver
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
                            for variable in ce.simpleVariables
                                ob = alight.observer.watch sys.ob, variable, ->
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
                sys.watchList.push d
                injectToRootLine scope

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
                delete sys.watches[key]
                i = sys.watchList.indexOf d
                if i >= 0
                    sys.watchList.splice i, 1

        if option.init
            callback r.value

        r


###
    cfg:
        no_return   - method without return (exec)
        string      - method will return result as string
        stringOrOneTime
        input   - list of input arguments
        full    - full response
        noBind  - get function without bind to scope
        rawExpression

###

do ->
    Scope::$compile = (src_exp, cfg) ->
        cfg = cfg or {}
        scope = @
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
                `func = function() { var __ = f1.apply(this, arguments); return '' + (__ || (__ == null?'':__)) }`

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


Scope::$eval = (exp) ->
    @.$compile(exp, {noBind: true})(@)



Scope::$getValue = (name) ->
    @.$eval name


Scope::$setValue = (name, value) ->
    fn = @.$compile name + ' = $value',
        input: ['$value']
        no_return: true
        noBind: true
    fn @, value


Scope::$destroy = () ->
    scope = this
    sys = scope.$system
    rootSys = scope.$system.root.$system

    # fire callbacks
    for cb in sys.destroy_callbacks
        cb scope
    sys.destroy_callbacks = []

    if rootSys.useObserver
        do ->
            # remove observer from root
            ob = sys.ob
            l = rootSys.observers
            i = l.indexOf ob
            if i >= 0
                l.splice i, 1
            alight.observer.unobserve ob

        # remove from root line
        if sys.lineActive
            sys.lineActive = false
            p = sys.prevSibling
            n = sys.nextSibling
            if p
                p.$system.nextSibling = n
            else
                # first scope
                rootSys.lineHead = n
            if n
                n.$system.prevSibling = p
            else
                # last scope
                rootSys.lineTail = p

    # remove children
    for it in sys.children.slice()
        it.$destroy()

    # remove from parent
    if scope.$parent
        i = scope.$parent.$system.children.indexOf scope
        scope.$parent.$system.children.splice i, 1

    # remove watch
    scope.$parent = null
    sys.watches = {}
    sys.watchList = []

    # remove watchAny
    cleanWatchAny = (l, r) ->
        lst = rootSys[r]
        for w in sys[l]
            i = lst.indexOf w
            if i >= 0
                lst.splice i, 1
        sys[l].length = 0
    cleanWatchAny 'watchAny', 'watchAnyAll'
    cleanWatchAny 'watchFinishScan', 'watchFinishScanAll'


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
                        if w.extraLoop
                            extraLoop = true
                        for callback in w.callbacks.slice()
                            callback.call scope, value
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
    changes = 0
    total = 0
    obTotal = 0

    rootSys = root.$system

    # observed
    for ob in rootSys.observers
        alight.observer.deliver ob
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
            if w.extraLoop
                extraLoop = true
            for callback in w.callbacks.slice()
                callback.call scope, value
    obTotal += rootSys.obList.length
    rootSys.obList.length = 0

    scope = rootSys.lineHead
    while scope
        sys = scope.$system

        # default watches
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
                    if w.extraLoop
                        extraLoop = true
                    for callback in w.callbacks.slice()
                        callback.call scope, value
                if alight.debug.scan > 1
                    console.log 'changed:', w.src

        scope = sys.nextSibling

    result.total = total
    result.obTotal = obTotal
    result.changes = changes
    result.extraLoop = extraLoop


Scope::$scanAsync = (callback) ->
    @.$scan
        late: true
        callback: callback


Scope::$scan = (cfg) ->
    cfg = cfg or {}
    if f$.isFunction cfg
        cfg =
            callback: cfg
    root = this.$system.root
    rootSys = root.$system
    if cfg.callback
        rootSys.scan_callbacks.push cfg.callback
    if cfg.late
        if rootSys.lateScan
            return
        rootSys.lateScan = true
        alight.nextTick ->
            if rootSys.lateScan
                root.$scan()
        return
    if rootSys.status is 'scaning'
        rootSys.extraLoop = true
        return
    rootSys.lateScan = false
    rootSys.status = 'scaning'
    # take scan_callbacks
    scan_callbacks = rootSys.scan_callbacks.slice()
    rootSys.scan_callbacks.length = 0


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

            rootSys.extraLoop = false

            if rootSys.useObserver
                scan_core2 root, result
            else
                scan_core root, result

            # call $any
            if result.changes
                for cb in rootSys.watchAnyAll
                    cb()
            if not result.extraLoop and not rootSys.extraLoop
                break
        if alight.debug.scan
            duration = get_time() - start
            console.log "$scan: (#{10-mainLoop}) #{result.total} + #{result.obTotal} / #{duration}ms"
    catch e
        alight.exceptionHandler e, '$scan, error in expression: ' + result.src,
            src: result.src
            result: result
    finally
        rootSys.status = null
        for callback in scan_callbacks
            callback.call root
        for callback in rootSys.watchFinishScanAll
            callback()

    if mainLoop is 0
        throw 'Infinity loop detected'


###
    $compileText = (text, cfg)
    cfg:
        result_on_static
        onStatic
        fullResponse
###
###
do ->
    isStatic = (data) ->
        for i in data
            if i.type is 'expression' and not i.static
                return false
        true

    Scope::$compileText = (text, cfg) ->
        scope = @
        cfg = cfg or {}

        sitem = alight.utilits.compile.buildSimpleText text, null
        if sitem
            if cfg.fullResponse
                response =
                    type: 'fn'
                    fn: sitem.fn
                    isSimple: sitem.isSimple
                    simpleVariables: sitem.simpleVariables
            else
                response = sitem.fn
            return response

        if text.indexOf(alight.utilits.pars_start_tag) < 0
            if cfg.result_on_static
                if cfg.fullResponse
                    response =
                        type: 'text'
                        text: text
                else
                    response = text
            else
                if cfg.fullResponse
                    response =
                        type: 'fn'
                        isStatic: true
                        fn: ->
                            text
                else
                    response = ->
                        text
            return response

        data = alight.utilits.parsText text
        data.scope = scope

        # data: type, value, fn, list, static
        watch_count = 0
        simple = true
        for d in data
            if d.type is 'expression'

                if d.list[0][0] is '='  # bind once
                    d.list[0] = '#bindonce ' + d.list[0].slice 1

                exp = d.list.join ' | '

                if exp[0] is '#'
                    simple = false
                    do (d=d) ->

                        async = false
                        env =
                            data: d
                            setter: (value) ->
                                d.value = value
                            finally: (value) ->
                                if arguments.length is 1
                                    env.setter value
                                d.static = true
                                if async and cfg.onStatic and isStatic(data)
                                    cfg.onStatic()
                        alight.text.$base scope, d, env
                        async = true
                    if not d.static
                        watch_count++
                else
                    ce = scope.$compile exp,
                        stringOrOneTime: true
                        full: true
                        rawExpression: true
                        noBind: true
                    if ce.oneTime
                        simple = false
                        do (d=d, ce=ce) ->
                            d.fn = ->
                                v = ce.fn scope
                                if v is undefined
                                    return ''
                                if v is null
                                    v = ''
                                d.fn = ->
                                    v
                                d.static = true
                                if cfg.onStatic and isStatic(data)
                                    cfg.onStatic()
                                v
                    else
                        d.fn = ce.fn
                        if ce.rawExpression
                            d.re = ce.rawExpression
                            if ce.isSimple
                                d.isSimple = true
                                d.simpleVariables = ce.simpleVariables
                        else
                            simple = false
                    watch_count++
        if watch_count
            if simple
                sitem = alight.utilits.compile.buildSimpleText text, data
                if cfg.fullResponse
                    response =
                        type: 'fn'
                        fn: sitem.fn
                        isSimple: sitem.isSimple
                        simpleVariables: sitem.simpleVariables
                else
                    response = sitem.fn
            else
                response = alight.utilits.compile.buildText text, data
                if cfg.fullResponse
                    response =
                        type: 'fn'
                        fn: response
            return response
        else
            fn = alight.utilits.compile.buildText text, data
            text = fn()
            if cfg.result_on_static
                if cfg.fullResponse
                    response =
                        type: 'text'
                        text: text
                else
                    response = text
            else
                response = ->
                    text
                if cfg.fullResponse
                    response =
                        type: 'fn'
                        isStatic: true
                        fn: response
            return response


Scope::$evalText = (exp) ->
    @.$compileText(exp)(@)


##
    Scope.$watchText(name, callback, config)
    config.readOnly
    config.onStatic
##
Scope::$watchText = (name, callback, config) ->
    scope = @
    sys = scope.$system
    config = config or {}

    if alight.debug.watchText
        console.log '$watchText', name

    w = sys.watches;
    d = w[name]
    if d
        if not config.readOnly
            d.extraLoop = true
    else
        # create watch object
        d =
            extraLoop: not config.readOnly
            isArray: false
            callbacks: []
            onStatic: []
            src: name

        ct = scope.$compileText name,
            fullResponse: true
            result_on_static: true
            onStatic: ->
                value = ct.fn.call scope

                d.exp = ->
                    value
                scope.$scanAsync ->
                    # remove watch
                    d.callbacks.length = 0
                    delete w[name]
                    i = sys.watchList.indexOf d
                    if i >= 0
                        sys.watchList.splice i, 1

                # call listeners
                for cb in d.onStatic
                    cb value
                null

        if ct.type is 'text'  # no watch
            return {
                value: ct.text
            }

        d.exp = ct.fn
        d.value = ct.fn scope
        w[name] = d

        if ct.isSimple and sys.root.$system.useObserver
            d.isObserved = true
            
            for variable in ct.simpleVariables
                ob = alight.observer.watch sys.ob, variable, ->
                    if sys.obFire[name]
                        return
                    sys.obFire[name] = true
                    sys.root.$system.obList.push [scope, d]
        else            
            sys.watchList.push d
            injectToRootLine scope

    if config.onStatic
        d.onStatic.push config.onStatic

    d.callbacks.push callback

    r =
        $: d
        value: d.value
        exp: d.exp
        stop: ->
            i = d.callbacks.indexOf callback
            if i >= 0
                d.callbacks.splice i, 1
                if d.callbacks.length isnt 0
                    return
                # remove watch
                delete w[name]
                i = sys.watchList.indexOf d
                if i >= 0
                    sys.watchList.splice i, 1

    r
###



alight.nextTick = do ->
    timer = null
    list = []
    exec = ->
        timer = null
        dlist = list.slice()
        list.length = 0
        for it in dlist
            callback = it[0]
            self = it[1]
            try
                callback.call self
            catch e
                alight.exceptionHandler e, '$nextTick, error in function',
                    fn: callback
        null

    (callback) ->
        list.push [callback, @]
        if timer
            return
        timer = setTimeout exec, 0


alight.getController = (name, scope) ->
    if scope.$ns and scope.$ns.controllers
        ctrl = scope.$ns.controllers[name]
    else
        ctrl = alight.controllers[name] or (enableGlobalControllers and window[name])
    if not ctrl
        throw 'Controller isn\'t found: ' + name
    if not (ctrl instanceof Function)
        throw 'Wrong controller: ' + name
    ctrl


alight.getFilter = (name, scope, param) ->
    if scope.$ns and scope.$ns.filters
        filter = scope.$ns.filters[name]
    else
        filter = alight.filters[name]
    if not filter
        throw 'Filter not found: ' + name
    filter


alight.applyBindings = (scope, element, config) ->
    if not element
        throw 'No element'

    if not scope
        scope = new alight.Scope()

    rootSys = scope.$system.root.$system

    finishBinding = not rootSys.finishBinding_lock
    if finishBinding
        rootSys.finishBinding_lock = true

    config = config or {}

    process scope, element, config
    
    if finishBinding
        rootSys.finishBinding_lock = false
        lst = rootSys.finishBinding_callbacks.slice()
        rootSys.finishBinding_callbacks.length = 0
        for cb in lst
            cb()
    null


alight.bootstrap = (input) ->
    if not input
        input = f$.find document, '[al-app]'
    if input instanceof HTMLElement
        input = [input]    
    if f$.isArray(input) or typeof(input.length) is 'number'
        for element in input
            if element.ma_bootstrapped
                continue
            element.ma_bootstrapped = true
            attr = f$.attr element, 'al-app'
            if attr
                if attr[0] is '#'
                    t = attr.split ' '
                    tag = t[0].substring(1)
                    ctrlName = t[1]
                    scope = alight.apps[tag]
                    if scope
                        if ctrlName
                            console.error "New controller on exists scope: al-app=\"#{attr}\""
                    else
                        alight.apps[tag] = scope = alight.Scope()
                        if ctrlName
                            ctrl = alight.getController ctrlName, scope
                            ctrl scope
                else
                    scope = alight.Scope()
                    ctrl = alight.getController attr, scope
                    ctrl scope
            else
                scope = alight.Scope()
            alight.applyBindings scope, element, { skip_attr: 'al-app' }
    else
        if f$.isObject(input) and input.$el
            scope = alight.Scope
                prototype: input

            for el in f$.find(document.body, input.$el)
                alight.applyBindings scope, el
            return scope
        else
            alight.exceptionHandler 'Error in bootstrap', 'Error in bootstrap',
                input: input
    null
