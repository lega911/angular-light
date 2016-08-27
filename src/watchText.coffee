
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

    alight.utils.optmizeElement = optmizeElement = (element) ->
        if element.nodeType is 1
            e = element.firstChild
            while e
                next = e.nextSibling
                optmizeElement e
                e = next
        else if element.nodeType is 3
            text = element.data
            mark = alight.utils.pars_start_tag
            i = text.indexOf(mark)
            if i < 0
                return
            if text.slice(i+mark.length).indexOf(mark) < 0
                return
            prev = 't'  # t, v, d, f
            current =
                value: ''
            result = [current]
            data = alight.utils.parsText text
            for d in data
                if d.type is 'text'
                    current.value += d.value
                else
                    exp = d.list.join '|'
                    wrapped = '{{' + exp + '}}'
                    lname = exp.match /^([^\w\d\s\$"'\(\u0410-\u044F\u0401\u0451]+)/
                    if lname
                        # directive
                        if prev is 't' or prev is 'd'
                            current.value += wrapped
                        else
                            current =
                                value: wrapped
                            result.push current
                        prev = 'd'
                    else if d.list.length is 1
                        if prev is 't' or prev is 'v'
                            current.value += wrapped
                        else
                            current =
                                value: wrapped
                            result.push current
                        prev = 'v'
                    else
                        # + filter
                        if prev is 't'
                            current.value += wrapped
                        else
                            current =
                                value: wrapped
                            result.push current

            if result.length < 2
                return

            e = element
            e.data = result[0].value
            for d in result[1..]
                n = document.createTextNode d.value
                f$.after e, n
                e = n
        return

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
            setterRaw: (value) ->
                if not option.updateRaw
                    return

                if value == null
                    point.value = ''
                else
                    point.value = '' + value
                option.updateRaw()
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

        scopeWrap cd, ->
            dir env.setter, option.exp, scope, env

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

        doUpdate = doUpdateRaw = doFinally = ->

        for d in data # { type list value }
            if d.type is 'expression'

                # check for a text directive
                exp = d.list.join '|'
                lname = exp.match /^([^\w\d\s\$"'\(\u0410-\u044F\u0401\u0451]+)/
                if lname
                    d.isDir = true
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
                        updateRaw: ->
                            doUpdateRaw()
                        finally: ->
                            doUpdate()
                            doFinally()
                    noCache = true
                    if d.type isnt 'text'
                        canUseSimpleBuilder = false
                else
                    ce = alight.utils.compile.expression exp,
                        string: true

                    if not ce.filter
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
                        d.watched = true
                        do (d) ->
                            cd.watch exp, (value) ->
                                value ?= ''
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

        watchObject =
            callback: callback
            el: config.element
            ea: config.elementAttr

        data.scope = cd.scope
        fn = alight.utils.compile.buildText expression, data

        doUpdateRaw = ->
            execWatchObject cd.scope, watchObject, fn()                

        if watchCount
            w = null
            resultValue = ''
            doUpdate = ->
                resultValue = fn()
                return
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
                return
            privateValue = ->
                resultValue
            # watch for expressions
            for d in data
                if d.type is 'expression'
                    if d.isDir or d.watched
                        continue
                    d.watched = true
                    do (d, exp=d.list.join ' | ') ->
                        cd.watch exp, (value) ->
                            value ?= ''
                            d.value = value
                            doUpdate()
            doUpdate()
            w = cd.watch privateValue, callback,
                element: config.element
                elementAttr: config.elementAttr
        else
            # pure text directive
            updatePlanned = false
            fireCallback = ->
                updatePlanned = false
                doUpdateRaw()

            doUpdate = ->
                if updatePlanned
                    return
                updatePlanned = true
                cd.watch '$onScanOnce', fireCallback

            doUpdate()
        return

    ChangeDetector::watchText = watchText
