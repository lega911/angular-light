do ->
    alight.hooks.attribute.unshift
        code: 'events'
        fn: ->
            d = @.attrName.match /^\@([\w\.]+)$/
            if not d
                d = @.attrName.match /^\(([\w\.]+)\)$/
                if not d
                    return

            @.ns = 'al'
            @.name = 'on'
            @.attrArgument = d[1]
            return

    alight.d.al.on =
        alias: {}
        priority: 10
        init: (scope, element, expression, env) ->
            if not env.attrArgument
                return
            event = env.attrArgument.split('.')[0]
            handler = makeEvent env.attrArgument, directiveOption[event]
            handler scope, element, expression, env

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

    makeEvent = (attrArgument, option) ->
        option = option or {}
        args = attrArgument.split '.'
        eventName = args[0]
        stop = option.stop or false
        prevent = option.prevent or false
        filtered = false
        scan = true
        eventList = null
        eventCondition = null

        alias = alight.d.al.on.alias[eventName]
        if alias
            if typeof(alias) is 'string'
                alias =
                    event: alias.split /\s+/
            else if Array.isArray alias
                alias =
                    event: alias
            eventList = alias.event
            eventCondition = alias.condition

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

            handler = (event) ->
                if filtered
                    if not filter[event.keyCode]
                        return
                    if filterExt.length
                        for extraKey in filterExt
                            if not keyModifiers[extraKey](event)
                                return
                if eventCondition
                    if not eventCondition scope, event
                        return

                if prevent
                    event.preventDefault()
                if stop
                    event.stopPropagation()
                try
                    fn scope, event
                catch error
                    alight.exceptionHandler error, "Error in event: #{attrArgument} = #{expression}",
                        attr: attrArgument
                        exp: expression
                        scope: scope
                        element: element
                        event: event
                if scan
                    scope.$scan()
                return

            if eventList
                for e in eventList
                    element.addEventListener e, handler
            else
                element.addEventListener eventName, handler
            scope.$watch '$destroy', ->
                if eventList
                    for e in eventList
                        element.removeEventListener e, handler
                else
                    element.removeEventListener eventName, handler
            return

    directiveOption =
        click:
            stop: true
            prevent: true
        dblclick:
            stop: true
            prevent: true
        submit:
            stop: true
            prevent: true
        keyup:
            filtered: true
        keypress:
            filtered: true
        keydown:
            filtered: true
