# Angular light
# version: 0.8.33 / 2015-04-04

# init
alight.version = '0.8.33'
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
alight.utilits = alight.utils = {}
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
        '$scanNoChanges'
    w = scope.$watchText text, setter
    setter w.value


bindText = (scope, node) ->
    text = node.data
    if text.indexOf(alight.utilits.pars_start_tag) < 0
        return
    setter = (result) ->
        node.nodeValue = result
        '$scanNoChanges'
    w = scope.$watchText text, setter
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


bindElement = do ->
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
                bindNode scope, node
        null


nodeTypeBind =
    1: bindElement      # element
    3: bindText  # text
    8: bindComment  # comment


bindNode = (scope, node, option) ->
    if alight.utils.getData node, 'skipBinding'
        return
    fn = nodeTypeBind[node.nodeType]
    if fn
        fn scope, node, option


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
        scope = alight.Scope()

    root = scope.$system.root

    finishBinding = not root.finishBinding_lock
    if finishBinding
        root.finishBinding_lock = true

    config = config or {}

    bindNode scope, element, config
    
    if finishBinding
        root.finishBinding_lock = false
        lst = root.watchers.finishBinding.slice()
        root.watchers.finishBinding.length = 0
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

            if input.$el instanceof HTMLElement
                alight.applyBindings scope, input.$el
            else
                for el in f$.find(document.body, input.$el)
                    alight.applyBindings scope, el
            return scope
        else
            alight.exceptionHandler 'Error in bootstrap', 'Error in bootstrap',
                input: input
    null
