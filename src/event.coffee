do ->
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

    makeEvent = (event, option) ->
        option = option or {}
        (code, args) ->
            stop = option.stop or false
            prevent = option.prevent or false
            filtered = false
            scan = true
            filter = {}
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

    makeDefaultHandler = (code, args) ->
        event = args[0]
        makeEvent event

    dirs =
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

    alight.hooks.attribute.unshift
        code: 'events'
        fn: ->
            d = @.attrName.match /^\(([\w\.]+)\)$/
            if not d
                return
            code = d[1]

            args = code.split '.'
            event = args[0]
            makeHandler = if dirs[event] then dirs[event] else makeDefaultHandler

            @.directive =
                priority: 10
                link: makeHandler code, args
            return
