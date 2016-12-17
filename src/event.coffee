do ->
    alight.hooks.attribute.unshift
        code: 'events'
        fn: ->
            d = @.attrName.match /^\@([\w\.\-]+)$/
            if not d
                return

            @.ns = 'al'
            @.name = 'on'
            @.attrArgument = d[1]
            return

    ###
    eventModifier
        = 'keydown blur'
        = ['keydown', 'blur']
        =
            event: string or list
            fn: (event, env) ->
    ###

    alight.hooks.eventModifier = {}

    setKeyModifier = (name, key) ->
        alight.hooks.eventModifier[name] =
            event: ['keydown', 'keypress', 'keyup']
            fn: (event, env) ->
                if not event[key]
                    env.stop = true
                return

    setKeyModifier 'alt', 'altKey'
    setKeyModifier 'control', 'ctrlKey'
    setKeyModifier 'ctrl', 'ctrlKey'
    setKeyModifier 'meta', 'metaKey'
    setKeyModifier 'shift', 'shiftKey'

    formatModifier = (modifier, filterByEvents) ->
        result = {}
        if typeof(modifier) is 'string'
            result.event = modifier
        else if typeof(modifier) is 'object' and modifier.event
            result.event = modifier.event

        if typeof(result.event) is 'string'
            result.event = result.event.split /\s+/

        if filterByEvents
            if result.event
                inuse = false
                for e in result.event
                    if filterByEvents.indexOf(e) >= 0
                        inuse = true
                        break
                if not inuse
                    return null

        if f$.isFunction modifier
            result.fn = modifier
        else if modifier.fn
            result.fn = modifier.fn

        if modifier.init
            result.init = modifier.init

        result

    alight.d.al.on = (scope, element, expression, env) ->
        env.fastBinding = true
        if not env.attrArgument
            return
        eventName = env.attrArgument.split('.')[0]
        ev = makeEvent env.attrArgument, eventOption[eventName]

        ev.scope = scope
        ev.element = element
        ev.expression = expression
        ev.cd = cd = env.changeDetector
        ev.fn = cd.compile expression,
            no_return: true
            input: ['$event', '$element', '$value']

        eventHandler = (e) ->
            handler ev, e

        for e in ev.eventList
            f$.on element, e, eventHandler
        if ev.initFn
            ev.initFn scope, element, expression, env
        cd.watch '$destroy', ->
            for e in ev.eventList
                f$.off element, e, eventHandler
        return

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

    eventOption =
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
            filterByKey: true
        keypress:
            filterByKey: true
        keydown:
            filterByKey: true

    makeEvent = (attrArgument, option) ->
        option = option or {}
        ev =
            attrArgument: attrArgument
            throttle: null
            throttleTime: 0
            debounce: null
            debounceId: null
            initFn: null
            eventList: null
            stop: option.stop or false
            prevent: option.prevent or false
            scan: true
            modifiers: []

        args = attrArgument.split '.'
        eventName = args[0]
        filterByKey = null

        modifier = alight.hooks.eventModifier[eventName]
        if modifier
            modifier = formatModifier modifier
            if modifier.event
                ev.eventList = modifier.event
                if modifier.fn
                    ev.modifiers.push modifier
                if modifier.init
                    ev.initFn = modifier.init
        if not ev.eventList
            ev.eventList = [eventName]

        for k in args.slice(1)
            if k is 'stop'
                ev.stop = true
                continue
            if k is 'prevent'
                ev.prevent = true
                continue
            if k is 'nostop'
                ev.stop = false
                continue
            if k is 'noprevent'
                ev.prevent = false
                continue
            if k is 'noscan'
                ev.scan = false
                continue
            if k.substring(0, 9) is 'throttle-'
                ev.throttle = Number k.substring 9
                continue
            if k.substring(0, 9) is 'debounce-'
                ev.debounce = Number k.substring 9
                continue

            modifier = alight.hooks.eventModifier[k]
            if modifier
                modifier = formatModifier modifier, ev.eventList
                if modifier
                    ev.modifiers.push modifier
                continue

            if not option.filterByKey
                continue

            if filterByKey is null
                filterByKey = {}

            if keyCodes[k]
                k = keyCodes[k]
            filterByKey[k] = true
        ev.filterByKey = filterByKey
        ev

    getValue = (ev, event) ->
        element = ev.element
        if element.type is 'checkbox'
            element.checked
        else if element.type is 'radio'
            element.value or element.checked
        else if event.component
            event.value
        else
            element.value

    execute = (ev, event) ->
        try
            ev.fn ev.cd.locals, event, ev.element, getValue ev, event
        catch error
            alight.exceptionHandler error, "Error in event: #{ev.attrArgument} = #{ev.expression}",
                attr: ev.attrArgument
                exp: ev.expression
                scope: ev.scope
                cd: ev.cd
                element: ev.element
                event: event
        if ev.scan
            ev.cd.scan()
        return

    handler = (ev, event) ->
        if ev.filterByKey
            if not ev.filterByKey[event.keyCode]
                return

        if ev.modifiers.length
            env =
                stop: false
            for modifier in ev.modifiers
                modifier.fn event, env
                if env.stop
                    return

        if ev.prevent
            event.preventDefault()
        if ev.stop
            event.stopPropagation()

        if ev.debounce
            if ev.debounceId
                clearTimeout ev.debounceId
            ev.debounceId = setTimeout ->
                ev.debounceId = null
                execute ev, event
            , ev.debounce
        else if ev.throttle
            if ev.throttleTime < Date.now()
                ev.throttleTime = Date.now() + ev.throttle
                execute ev, event
        else
            execute ev, event
        return
