do ->
    alight.hooks.attribute.unshift
        code: 'events'
        fn: ->
            d = @.attrName.match /^\(([\w\.]+)\)$/
            if not d
                return

            @.ns = 'al'
            @.name = 'on'
            @.attrArgument = d[1]
            return

    alight.d.al.on =
        priority: 10
        init: (scope, element, expression, env) ->
            if not env.attrArgument
                return
            parts = env.attrArgument.split '.'
            event = parts[0]

            handler = directives[event]
            if not handler
                handler = makeEvent event
            handler(env.attrArgument, parts)(scope, element, expression, env)

    keyCodes =
        enter: 13
        tab: 9
        delete: 46
        backspace: 8
        esc: 27
        space: 32
        up: 38
        down: 40
        left: 37
        right: 39

    keyModifiers =
        alt: (event) -> event.altKey
        control: (event) -> event.ctrlKey
        meta: (event) -> event.metaKey
        shift: (event) -> event.shiftKey

    makeEvent = (event, option) ->
        option = option or {}
        (code, args) ->
            stop = option.stop or false
            prevent = option.prevent or false
            filtered = false
            scan = true
            filter = {}
            filterExt = []
            for k in args.slice(1)
                if k is 'stop'
                    stop = true
                    continue
                if k is 'prevent'
                    prevent = true
                    continue
                if k is 'nostop'
                    stop = false
                    continue
                if k is 'noprevent'
                    prevent = false
                    continue
                if k is 'noscan'
                    scan = false
                    continue
                if not option.filtered
                    continue

                filtered = true
                if keyModifiers[k]
                    filterExt.push k
                    continue

                if keyCodes[k]
                    k = keyCodes[k]
                filter[k] = true

            (scope, element, expression, env) ->
                fn = scope.$compile expression,
                    no_return: true
                    input: ['$event']

                handler = (e) ->
                    if filtered
                        if not filter[e.keyCode]
                            return
                        if filterExt.length
                            for extraKey in filterExt
                                if not keyModifiers[extraKey](e)
                                    return

                    if prevent
                        e.preventDefault()
                    if stop
                        e.stopPropagation()
                    try
                        fn scope, e
                    catch e
                        alight.exceptionHandler e, "Error in event: #{code} = #{expression}",
                            attr: code
                            exp: expression
                            scope: scope
                            element: element
                    if scan
                        scope.$scan()
                    return

                element.addEventListener event, handler
                scope.$watch '$destroy', ->
                    element.removeEventListener event, handler
                return

    directives =
        click: makeEvent 'click',
            stop: true
            prevent: true
        dblclick: makeEvent 'dblclick',
            stop: true
            prevent: true
        submit: makeEvent 'submit',
            stop: true
            prevent: true
        keyup: makeEvent 'keyup',
            filtered: true
        keypress: makeEvent 'keypress',
            filtered: true
        keydown: makeEvent 'keydown',
            filtered: true
