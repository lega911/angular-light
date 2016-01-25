
# init
alight.version = '{{{version}}}'
alight.debug =
    scan: 0
    directive: false
    watch: false
    watchText: false
    parser: false


do ->
    alight.hooks.attribute = ext = []

    ext.push
        code: 'dataPrefix'
        fn: ->
            if @.attrName[0..4] is 'data-'
                @.attrName = @.attrName[5..]
            return

    ext.push
        code: 'colonNameSpace'
        fn: ->
            if @.directive
                return

            j = @.attrName.indexOf ':'
            if j < 0
                j = @.attrName.indexOf '-'
            if j < 0
                @.result = 'noNS'
                @.stop = true
                return
            else
                @.ns = @.attrName.substring 0, j
                @.name = @.attrName.substring(j+1).replace /(-\w)/g, (m) ->
                    m.substring(1).toUpperCase()
            return

    ext.push
        code: 'getScopeDirective'
        fn: ->
            if @.directive
                return

            $ns = @.cd.scope.$ns
            if $ns and $ns.directives
                path = $ns.directives[@.ns]
                if path
                    @.directive = path[@.name]
                    if not @.directive
                        if not $ns.inheritGlobal
                            @.result = 'noDirective'
                            @.stop = true
                            return
                else
                    if not $ns.inheritGlobal
                        @.result = 'noNS'
                        @.stop = true
            return

    ext.push
        code: 'getGlobalDirective'
        fn: ->
            if @.directive
                return

            path = alight.d[@.ns]
            if not path
                @.result = 'noNS'
                @.stop = true
                return

            @.directive = path[@.name]
            if not @.directive
                @.result = 'noDirective'
                @.stop = true
            return

    ext.push
        code: 'cloneDirective'
        fn: ->
            r = @.directive
            dir = {}
            if f$.isFunction r
                dir.init = r
            else if f$.isObject r
                for k, v of r
                    dir[k] = v
            else
                throw 'Wrong directive: ' + ns + '.' + name
            dir.priority = r.priority or 0
            dir.restrict = r.restrict or 'A'

            if dir.restrict.indexOf(@.attrType) < 0
                throw 'Directive has wrong binding (attribute/element): ' + name

            @.directive = dir
            return

    ext.push
        code: 'preprocessor'
        fn: ->
            ns = @.ns
            name = @.name
            directive = @.directive
            directive.$init = (cd, element, value, env) ->

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
                    doBinding: false
                    # args: args
                    directive: directive
                    isDeferred: false
                    procLine: alight.hooks.directive
                    makeDeferred: ->
                        dscope.isDeferred = true
                        dscope.doBinding = true         # continue binding
                        dscope.retStopBinding = true    # stop binding for child elements

                        ->
                            dscope.isDeferred = false
                            doProcess()

                if directive.stopBinding
                    env.stopBinding = true

                doProcess()
                return
            return


do ->
    ext = alight.hooks.directive

    ext.push
        code: 'init'
        fn: ->
            if @.directive.init
                if alight.debug.directive
                    if @.directive.scope
                        console.warn "#{@.ns}-#{@.name} uses scope and init together, probably you need use link instead of init"
                @.env.changeDetector = @.cd
                @.cd.scope.$changeDetector = @.cd
                result = @.directive.init @.cd.scope, @.element, @.value, @.env
                if result and result.start
                    result.start()
                @.cd.scope.$changeDetector = null
            return

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
            return

    ext.push
        code: 'template'
        fn: ->
            if @.directive.template
                if @.element.nodeType is 1
                    @.element.innerHTML = @.directive.template
                else if @.element.nodeType is 8
                    el = document.createElement 'p'
                    el.innerHTML = @.directive.template.trim()
                    el = el.firstChild
                    f$.after @.element, el
                    @.element = el
                    @.doBinding = true
            return

    ext.push
        code: 'scope'
        fn: ->
            # scope: false, true, 'root'
            if not @.directive.scope
                return

            parentCD = @.cd

            switch @.directive.scope
                when true
                    scope = alight.Scope
                        $parent: parentCD.scope
                        childFromChangeDetector: parentCD
                    childCD = scope.$rootChangeDetector
                when 'root'
                    scope = alight.Scope
                        $parent: parentCD.scope

                    childCD = scope.$rootChangeDetector
                    parentCD.watch '$destroy', ->
                        childCD.destroy()
                else
                    throw 'Wrong scope value: ' + @.directive.scope

            @.env.parentChangeDetector = parentCD
            @.cd = childCD

            @.doBinding = true
            @.retStopBinding = true
            return

    ext.push
        code: 'link'
        fn: ->
            if @.directive.link
                @.env.changeDetector = @.cd
                @.cd.scope.$changeDetector = @.cd
                result = @.directive.link @.cd.scope, @.element, @.value, @.env
                if result and result.start
                    result.start()
                @.cd.scope.$changeDetector = null
            return

    ext.push
        code: 'scopeBinding'
        fn: ->
            if @.doBinding and not @.env.stopBinding
                alight.bind @.cd, @.element,
                    skip_attr: @.env.skippedAttr()
            if @.retStopBinding
                @.env.stopBinding = true
            return


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
        else if args.attr_type is 'M'
            args.list.push base
        return

    (attrName, args) ->
        if args.skip_attr.indexOf(attrName) >= 0
            return addAttr attrName, args,
                skip: true

        attrSelf =
            attrName: attrName
            attrType: args.attr_type
            element: args.element
            cd: args.cd
            result: null
            # result, stop, ns, name, directive

        for attrHook in alight.hooks.attribute
            attrHook.fn.call attrSelf
            if attrSelf.stop
                break

        if attrSelf.result is 'noNS'
            addAttr attrName, args
            return

        if attrSelf.result is 'noDirective'
            addAttr attrName, args,
                noDirective: true
            return

        args.list.push
            name: attrName
            directive: attrSelf.directive
            priority: attrSelf.directive.priority
            attrName: attrName
        return


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

    cd.watchText text, null,
        element: element
        elementAttr: attrName
    true


bindText = (cd, element) ->
    text = element.data
    if text.indexOf(alight.utils.pars_start_tag) < 0
        return
    cd.watchText text, null,
        element: element
    true


bindComment = (cd, element, option) ->
    text = element.nodeValue.trim()
    if text[0..9] isnt 'directive:'
        return
    text = text[10..].trim()
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
        throw "Comment directive not found: #{dirName}"

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
        directive.$init cd, element, value, env
    catch e
        alight.exceptionHandler e, 'Error in directive: ' + d.name,
            value: value
            env: env
            cd: cd
            scope: cd.scope
            element: element
    if env.skipToElement
        return {
            directive: 1
            skipToElement: env.skipToElement
        }

    directive: 1
    skipToElement: null


bindElement = do ->
    takeAttr = (name, skip) ->
        if arguments.length is 1
            skip = true
        for attr in @.attributes
            if attr.attrName isnt name
                continue
            if skip
                attr.skip = true
            value = @.element.getAttribute name
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
            skipToElement: null
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
            for attr in element.attributes
                testDirective attr.name, args

            if config.attachDirective
                for attrName, attrValue of config.attachDirective
                    testDirective attrName, args

            # sort by priority
            list = list.sort sortByPriority

            for d in list
                if d.skip
                    continue
                if d.noDirective
                    throw "Directive not found: #{d.name}"
                d.skip = true
                if config.attachDirective and config.attachDirective[d.attrName]
                    value = config.attachDirective[d.attrName]
                else
                    value = element.getAttribute d.attrName
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
                        stopBinding: false
                    if alight.debug.directive
                        console.log 'bind', d.attrName, value, d
                    try
                        directive.$init cd, element, value, env
                    catch e
                        alight.exceptionHandler e, 'Error in directive: ' + d.attrName,
                            value: value
                            env: env
                            cd: cd
                            scope: cd.scope
                            element: element

                    if env.stopBinding
                        skipChildren = true
                        break

                    if env.skipToElement
                        bindResult.skipToElement = env.skipToElement

        if !skipChildren
            # text bindings
            skipToElement = null
            childNodes = for childElement in element.childNodes
                childElement
            for childElement in childNodes
                if not childElement
                    continue
                if skipToElement
                    if skipToElement is childElement
                        skipToElement = null
                    continue
                r = bindNode cd, childElement
                bindResult.directive += r.directive
                bindResult.text += r.text
                bindResult.attr += r.attr
                bindResult.hook += r.hook
                skipToElement = r.skipToElement

        bindResult


bindNode = (cd, element, option) ->
    result =
        directive: 0
        text: 0
        attr: 0
        hook: 0
        skipToElement: null
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
        result.skipToElement = r.skipToElement
    else if element.nodeType is 3
        if bindText cd, element, option
            result.text++
    else if element.nodeType is 8
        r = bindComment cd, element, option
        if r
            result.directive += r.directive
            result.skipToElement = r.skipToElement
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


alight.bind = alight.applyBindings = (scope, element, option) ->
    if not element
        throw 'No element'

    if not scope
        throw 'No Scope'

    option = option or {}

    if scope instanceof alight.core.ChangeDetector
        cd = scope
    else
        cd = option.changeDetector or scope.$changeDetector or scope.$rootChangeDetector
    root = cd.root

    finishBinding = not root.finishBinding_lock
    if finishBinding
        root.finishBinding_lock = true
        root.bindingResult =
            directive: 0
            text: 0
            attr: 0
            hook: 0

    result = bindNode cd, element, option

    root.bindingResult.directive += result.directive
    root.bindingResult.text += result.text
    root.bindingResult.attr += result.attr
    root.bindingResult.hook += result.hook

    cd.digest()
    if finishBinding
        #cd.scan()
        root.finishBinding_lock = false
        lst = root.watchers.finishBinding.slice()
        root.watchers.finishBinding.length = 0
        for cb in lst
            cb()
        result.total = root.bindingResult

    result


alight.bootstrap = (input, data) ->
    if not input
        alight.bootstrap '[al-app]'
        alight.bootstrap '[al\\:app]'
        alight.bootstrap '[data-al-app]'
        return
    else if typeof(input) is 'string'
        input = document.querySelectorAll input
    else if f$.isElement input
        input = [input]
    if Array.isArray(input) or typeof(input.length) is 'number'
        lastScope = null
        if data
            oneScope = alight.Scope
                customScope: data
        for element in input
            if element.ma_bootstrapped  # TODO change to getData/setData
                continue
            element.ma_bootstrapped = true
            if oneScope
                scope = oneScope
            else
                scope = alight.Scope()
            option =
                skip_attr: ['al-app', 'al:app']

            ctrlName = element.getAttribute('al-app') or element.getAttribute 'al:app' or element.getAttribute 'data-al-app'
            if ctrlName
                option.attachDirective =
                    'al-ctrl': ctrlName

            alight.bind scope, element, option
            lastScope = scope
        return lastScope
    alight.exceptionHandler 'Error in bootstrap', 'Error input arguments',
        input: input
    return
