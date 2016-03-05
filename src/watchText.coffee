
do ->
    ###
        Scope.$watchText(name, callback, config)
        args:
            config.readOnly
            config.onStatic
        result:
            isStatic: flag
            $: watch-object
            value: current value
            exp: expression
            stop: function to stop watch


        kind of expressions
            simple: {{model}}
            text-directive: {{#dir model}} {{=staticModel}} {{::oneTimeBinding}}
            with function: {{fn()}}
            with filter: {{value | filter}}

    ###

    getId = do ->
        i = 0
        ->
            i++
            'wt' + i

    alight.text.$base = (option) ->
        point = option.point

        cd = option.cd
        scope = cd.scope
        if scope.$ns and scope.$ns.text
            dir = scope.$ns.text[option.name]
        else
            dir = alight.text[option.name]
        if not dir
            throw 'No directive alight.text.' + option.name

        env =
            changeDetector: cd
            setter: (value) ->
                if not option.update
                    return

                if value == null
                    point.value = ''
                else
                    point.value = '' + value
                option.update()
            finally: (value) ->  # prebuild finally
                if not option.finally
                    return

                if value == null
                    point.value = ''
                else
                    point.value = '' + value
                point.type = 'text'
                option.finally()

                option.update = null
                option.finally = null

        scope.$changeDetector = cd
        dir env.setter, option.exp, scope, env
        scope.$changeDetector = null

    watchText = (expression, callback, config) ->
        config = config or {}
        cd = @
        if alight.debug.watchText
            console.log '$watchText', expression

        # test simple text
        st = alight.utils.compile.buildSimpleText expression, null
        if st
            cd.watch expression, callback,
                watchText: st
                element: config.element
                elementAttr: config.elementAttr
            return

        data = alight.utils.parsText expression

        watchCount = 0
        canUseSimpleBuilder = true
        noCache = false

        doUpdate = doFinally = ->

        for d in data # { type list value }
            if d.type is 'expression'

                # check for a text directive
                exp = d.list.join ' | '
                lname = exp.match /^([^\w\d\s\$"'\(\u0410-\u044F\u0401\u0451]+)/
                if lname
                    name = lname[1]
                    if name is '#'
                        i = exp.indexOf ' '
                        if i < 0
                            name = exp.substring 1
                            exp = ''
                        else
                            name = exp.slice 1, i
                            exp = exp.slice i
                    else
                        exp = exp.substring name.length

                    alight.text.$base
                        name: name
                        exp: exp
                        cd: cd
                        point: d
                        update: ->
                            doUpdate()
                        finally: ->
                            doUpdate()
                            doFinally()
                    noCache = true
                    if d.type isnt 'text'
                        canUseSimpleBuilder = false
                else
                    ce = alight.utils.compile.expression exp,
                        string: true

                    if not ce.filters
                        d.fn = ce.fn
                        if not ce.rawExpression
                            throw 'Error'
                        if ce.isSimple and ce.simpleVariables.length is 0  # static expression
                            d.type = 'text'
                            d.value = d.fn()
                        else
                            d.re = ce.rawExpression
                            watchCount++
                    else
                        watchCount++
                        canUseSimpleBuilder = false
                        do (d) ->
                            cd.watch exp, (value) ->
                                `if(value == null) value = ''`
                                d.value = value
                                doUpdate()

        if canUseSimpleBuilder
            if not watchCount
                # static text
                value = ''
                for d in data
                    value += d.value
                cd.watch '$onScanOnce', ->
                    execWatchObject cd.scope,
                        callback: callback
                        el: config.element
                        ea: config.elementAttr
                    , value
                return

            if noCache
                st = alight.utils.compile.buildSimpleText null, data
            else
                st = alight.utils.compile.buildSimpleText expression, data
            cd.watch expression, callback,
                watchText:
                    fn: st.fn
                element: config.element
                elementAttr: config.elementAttr
            return

        if watchCount
            w = null
            resultValue = ''
            data.scope = cd.scope
            fn = alight.utils.compile.buildText expression, data
            doUpdate = ->
                resultValue = fn()
            doFinally = ->
                i = true
                for d in data
                    if d.type is 'expression'
                        i = false
                        break
                if not i
                    return
                cd.watch '$finishScanOnce', ->
                    w.stop()
                if config.onStatic
                    config.onStatic()
            privateValue = ->
                resultValue
            doUpdate()
            w = cd.watch privateValue, callback,
                element: config.element
                elementAttr: config.elementAttr
        else
            # clear text directive
            data.scope = cd.scope
            fn = alight.utils.compile.buildText expression, data

            watchObject =
                callback: callback
                el: config.element
                ea: config.elementAttr

            updatePlanned = false
            fireCallback = ->
                updatePlanned = false
                execWatchObject cd.scope, watchObject, fn()

            doUpdate = ->
                if updatePlanned
                    return
                updatePlanned = true
                cd.watch '$onScanOnce', fireCallback
            doUpdate()
        return

    ChangeDetector::watchText = watchText

    Scope::$watchText = (expression, callback, option) ->
        cd = @.$changeDetector
        if not cd and not @.$rootChangeDetector.children.length  # no child scopes
            cd = @.$rootChangeDetector
        if cd
            cd.watchText expression, callback, option
        else
            alight.exceptionHandler '', 'You can do $watchText during binding only: ' + expression,
                expression: expression
                option: option
                scope: @
        return
