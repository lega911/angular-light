
# init
alight.version = '{{{version}}}'
alight.debug =
    scan: 0
    directive: false
    watch: false
    watchText: false
    parser: false


alight.directivePreprocessor = (attrName, args) ->
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

    raw = null
    $ns = args.cd.scope.$ns
    if $ns and $ns.directives
        path = $ns.directives[ns]
        if path
            raw = path[name]
            if not raw
                if not $ns.inheritGlobal
                    return { noDirective: true }
        else
            if not $ns.inheritGlobal
                return { noNs: true }

    if not raw
        path = alight.d[ns]
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

    dir.$init = (cd, element, value, env) ->

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
            value: value
            cd: cd
            env: env
            ns: ns
            name: name
            args: args
            directive: dir
            result: {}
            
            isDeferred: false
            procLine: alight.hooks.directive
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
    ext = alight.hooks.directive

    ext.push
        code: 'init'
        fn: ->
            if @.directive.init
                @.result = @.directive.init @.cd, @.element, @.value, @.env
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
                    @.doBinding = true

    ext.push
        code: 'scope'
        fn: ->
            # scope: false, true
            # ChangeDetector: false, true, 'root'
            if not (@.directive.scope or @.directive.ChangeDetector)
                return

            parentCD = @.cd

            if @.directive.scope
                scope =
                    $parent: parentCD.scope
            else
                scope = parentCD.scope

            if @.directive.ChangeDetector is 'root'
                @.cd = childCD = alight.ChangeDetector scope
                parentCD.watch '$destroy', ->
                    childCD.destroy()
            else
                @.cd = parentCD.new scope

            @.result.owner = true
            @.doBinding = true

    ext.push
        code: 'link'
        fn: ->
            if @.directive.link
                @.directive.link @.cd, @.element, @.value, @.env

    ext.push
        code: 'scopeBinding'
        fn: ->
            if @.doBinding
                alight.applyBindings @.cd, @.element,
                    skip_attr: @.env.skippedAttr()


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


attrBinding = (cd, element, value, attrName) ->
    text = value
    if text.indexOf(alight.utils.pars_start_tag) < 0
        return

    setter = (result) ->
        f$.attr element, attrName, result
        '$scanNoChanges'
    cd.watchText text, setter
    true


bindText = (cd, element) ->
    text = element.data
    if text.indexOf(alight.utils.pars_start_tag) < 0
        return
    setter = (result) ->
        element.nodeValue = result
        '$scanNoChanges'
    cd.watchText text, setter
    true


bindComment = (cd, element, option) ->
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
        cd: cd
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
        result = directive.$init cd, element, value, env
        if result and result.start
            result.start()
    catch e
        alight.exceptionHandler e, 'Error in directive: ' + d.name,
            value: value
            env: env
            cd: cd
            scope: cd.scope
            element: element
    true


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

    (cd, element, config) ->
        bindResult =
            directive: 0
            text: 0
            attr: 0
            hook: 0
        config = config || {}
        skipChildren = false
        skip_attr = config.skip_attr or []
        if not (skip_attr instanceof Array)
            skip_attr = [skip_attr]

        if !config.skip_top
            args =
                list: list = []
                element: element
                skip_attr: skip_attr
                attr_type: 'E'
                cd: cd
            
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
                    if attrBinding cd, element, value, d.attrName
                        bindResult.attr++
                else
                    bindResult.directive++
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
                        result = directive.$init cd, element, value, env
                        if result and result.start
                            result.start()
                    catch e
                        alight.exceptionHandler e, 'Error in directive: ' + d.attrName,
                            value: value
                            env: env
                            cd: cd
                            scope: cd.scope
                            element: element

                    if result and result.owner
                        skipChildren = true
                        break

        if !skipChildren
            # text bindings
            for childElement in f$.childNodes element
                if not childElement
                    continue
                r = bindNode cd, childElement
                bindResult.directive += r.directive
                bindResult.text += r.text
                bindResult.attr += r.attr
                bindResult.hook += r.hook

        bindResult


bindNode = (cd, element, option) ->
    result =
        directive: 0
        text: 0
        attr: 0
        hook: 0
    if alight.utils.getData element, 'skipBinding'
        return result
    if alight.hooks.binding.length
        for h in alight.hooks.binding
            result.hook += 1
            r = h.fn cd, element, option
            if r and r.owner  # take control
                return result

    if element.nodeType is 1
        r = bindElement cd, element, option
        result.directive += r.directive
        result.text += r.text
        result.attr += r.attr
        result.hook += r.hook
    else if element.nodeType is 3
        if bindText cd, element, option
            result.text++
    else if element.nodeType is 8
        if bindComment cd, element, option
            result.directive++
    result


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
                    self: self
        null

    (callback) ->
        list.push [callback, @]
        if timer
            return
        timer = setTimeout exec, 0


alight.bind = alight.applyBindings = (cd, element, option) ->
    if not element
        throw 'No element'

    if not cd
        throw 'No CD'

    root = cd.root

    finishBinding = not root.finishBinding_lock
    if finishBinding
        root.finishBinding_lock = true
        root.bindingResult =
            directive: 0
            text: 0
            attr: 0
            hook: 0

    option = option or {}
    result = bindNode cd, element, option

    root.bindingResult.directive += result.directive
    root.bindingResult.text += result.text
    root.bindingResult.attr += result.attr
    root.bindingResult.hook += result.hook
    
    if finishBinding
        root.finishBinding_lock = false
        cd.scan()
        lst = root.watchers.finishBinding.slice()
        root.watchers.finishBinding.length = 0
        for cb in lst
            cb()
        result.total = root.bindingResult

    result


alight.bootstrap = (input) ->
    if not input
        input = f$.find document, '[al-app]'
    if typeof(input) is 'string'
        input = f$.find document.body, input
    if f$.isElement input
        input = [input]
    if f$.isArray(input) or typeof(input.length) is 'number'
        lastCD = null
        for element in input
            if element.ma_bootstrapped  # TODO change to getData/setData
                continue
            element.ma_bootstrapped = true
            attr = f$.attr element, 'al-app'
            cd = alight.ChangeDetector()
            alight.applyBindings cd, element,
                skip_attr: 'al-app'
            lastCD = cd
        return cd
    if f$.isObject input
        cd = alight.ChangeDetector input

        if f$.isElement input.$el
            alight.applyBindings cd, input.$el
        else if typeof(input.$el) is 'string'
            for el in f$.find document.body, input.$el
                alight.applyBindings cd, el
        else
            alight.exceptionHandler 'Error in bootstrap', '$el is required',
                input: input
        return cd
    else
        alight.exceptionHandler 'Error in bootstrap', 'Error input arguments',
            input: input
    null
