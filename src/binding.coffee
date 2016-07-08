
# init
alight.version = '{{{version}}}'
alight.debug =
    scan: 0
    directive: false
    watch: false
    watchText: false
    parser: false
    domOptimization: true
    doubleBinding: 0


doubleBinding = do ->
    if alight.core.DoubleBinding
        return alight.core.DoubleBinding()
    startDirective: ->
    finishDirective: ->


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
            if @.directive or @.name
                return

            parts = @.attrName.match /^(\w+)[\-\:](.+)$/
            if parts
                @.ns = parts[1]
                name = parts[2]
            else
                @.ns = '$global'
                name = @.attrName

            parts = name.match /^([^\.]+)\.(.*)$/
            if parts
                name = parts[1]
                @.attrArgument = parts[2]

            @.name = name.replace /(-\w)/g, (m) ->
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
                            if @.ns is '$global'
                                @.result = 'noNS'
                            else
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
                if @.ns is '$global'
                    @.result = 'noNS'
                else
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
            attrArgument = @.attrArgument or null
            directive = @.directive
            directive.$init = (cd, element, value, env) ->

                doProcess = ->
                    l = dscope.procLine
                    for dp, i in l
                        dp.fn.call dscope
                        if dscope.isDeferred
                            dscope.procLine = l[i+1..]
                            break
                    dscope.async = true
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
                        dscope.async = false

                        ->
                            dscope.isDeferred = false
                            if dscope.async
                                doProcess()

                if directive.stopBinding
                    env.stopBinding = true
                env.attrArgument = attrArgument

                doProcess()

                if dscope.retStopBinding
                    return 'stopBinding'
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

                cd_setActive @.cd.scope, @.cd
                result = @.directive.init @.cd.scope, @.element, @.value, @.env
                if result and result.start
                    result.start()
                cd_setActive @.cd.scope, null
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
                    childCD = cd_getRoot scope
                when 'root'
                    scope = alight.Scope
                        $parent: parentCD.scope

                    childCD = cd_getRoot scope
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
                cd_setActive @.cd.scope, @.cd
                result = @.directive.link @.cd.scope, @.element, @.value, @.env
                if result and result.start
                    result.start()
                cd_setActive @.cd.scope, null
            return

    ext.push
        code: 'scopeBinding'
        fn: ->
            if @.doBinding and not @.env.stopBinding
                alight.bind @.cd, @.element,
                    skip_attr: @.env.skippedAttr()
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
            if args.attr_type is 'E'
                args.list.push
                    name: attrName
                    priority: 0
                    attrName: attrName
                    noDirective: true
                return

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
    if alight.debug.doubleBinding
        doubleBinding.startDirective element, d.attrName, value
    try
        directive.$init cd, element, value, env
    catch e
        alight.exceptionHandler e, 'Error in directive: ' + d.name,
            value: value
            env: env
            cd: cd
            scope: cd.scope
            element: element
    if alight.debug.doubleBinding
        doubleBinding.finishDirective element, d.attrName
    if env.skipToElement
        return {
            directive: 1
            skipToElement: env.skipToElement
        }

    directive: 1
    skipToElement: null


Env = (option) ->
    for k, v of option
        @[k] = v
    @

Env::takeAttr = (name, skip) ->
    if arguments.length is 1
        skip = true
    for attr in @.attributes
        if attr.attrName isnt name
            continue
        if skip
            attr.skip = true
        value = @.element.getAttribute name
        return value or true

Env::skippedAttr = ->
    for attr in @.attributes
        if not attr.skip
            continue
        attr.attrName

Env::scan = (option) ->
    @.changeDetector.scan option

Env::watch = (name, callback, option) ->
    @.changeDetector.watch name, callback, option

Env::watchGroup = (keys, callback) ->
    @.changeDetector.watchGroup keys, callback

Env::watchText = (expression, callback, option) ->
    @.changeDetector.watchText expression, callback, option

Env::getValue = (name) ->
    @.changeDetector.getValue name

Env::setValue = (name, value) ->
    @.changeDetector.setValue name, value

Env::eval = (exp) ->
    @.changeDetector.getValue exp

###
    env.new(scope, option)
    env.new(scope, true)  - makes locals
    env.new(true)  - makes locals
###
Env::new = (scope, option) ->
    if option is true
        option =
            locals: true
    else if scope is true and not option?
        scope = null
        option =
            locals: true

    @.changeDetector.new scope, option

###
    env.bind(cd, element, option)
    env.bind(cd)
    env.bind(element)
    env.bind(element, cd)
    env.bind(option)
    env.bind(env.new(), option)
###
Env::bind = (_cd, _element, _option) ->
    @.stopBinding = true
    count = 0
    for a in arguments
        if a instanceof ChangeDetector
            cd = a
            count += 1
        if f$.isElement a
            element = a
            count += 1
    option = arguments[count]
    if not option
        option =
            skip_attr: @.skippedAttr()
    if not element
        element = @.element
    if not cd
        cd = @.changeDetector
    alight.bind cd, element, option


bindElement = do ->

    (cd, element, config) ->
        bindResult =
            directive: 0
            text: 0
            attr: 0
            hook: 0
            skipToElement: null
        config = config || {}
        skipChildren = false
        skip_attr = config.skip_attr or config.skip or []
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
            if attrName is 'script' or attrName is 'style'  # don't process script and style tags
                skipChildren = true

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
                    if alight.debug.doubleBinding
                        doubleBinding.startDirective element, d.attrName, value, true
                    if attrBinding cd, element, value, d.attrName
                        bindResult.attr++
                else
                    bindResult.directive++
                    directive = d.directive
                    env = new Env
                        element: element
                        attrName: d.attrName
                        attributes: list
                        stopBinding: false
                        elementCanBeRemoved: config.elementCanBeRemoved
                    if alight.debug.directive
                        console.log 'bind', d.attrName, value, d
                    if alight.debug.doubleBinding
                        doubleBinding.startDirective element, d.attrName, value
                    try
                        if directive.$init(cd, element, value, env) is 'stopBinding'
                            skipChildren = true
                    catch e
                        alight.exceptionHandler e, 'Error in directive: ' + d.attrName,
                            value: value
                            env: env
                            cd: cd
                            scope: cd.scope
                            element: element
                    if alight.debug.doubleBinding
                        doubleBinding.finishDirective element, d.attrName

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
        if alight.debug.doubleBinding
            doubleBinding.startDirective element, 'text', '', true
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
        cd = option.changeDetector or cd_getActive(scope) or cd_getRoot(scope)
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
                skip_attr: ['al-app', 'al:app', 'data-al-app']

            ctrlName = element.getAttribute('al-app') or element.getAttribute('al:app') or element.getAttribute('data-al-app')
            if ctrlName
                option.attachDirective =
                    'al-ctrl': ctrlName

            if alight.debug.domOptimization
                alight.utils.optmizeElement element

            alight.bind scope, element, option
            lastScope = scope
        return lastScope
    alight.exceptionHandler 'Error in bootstrap', 'Error input arguments',
        input: input
    return
