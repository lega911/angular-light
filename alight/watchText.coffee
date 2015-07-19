
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

    alight.text.$base = (conf) ->
        point = conf.point

        exp = conf.exp
        i = exp.indexOf ' '
        if i < 0
            dirName = exp.slice 1
            exp = ''
        else
            dirName = exp.slice 1, i
            exp = exp.slice i

        scope = conf.scope
        if scope.$ns and scope.$ns.text
            dir = scope.$ns.text[dirName]
        else
            dir = alight.text[dirName]
        if not dir
            throw 'No directive alight.text.' + dirName

        env =
            setter: (value) ->
                if value == null
                    point.value = ''
                else
                    point.value = '' + value
                conf.update()
            finally: (value) ->  # prebuild finally
                if value == null
                    point.value = ''
                else
                    point.value = '' + value
                point.type = 'text'
                conf.finally()

        dir env.setter, exp, scope, env
            

    alight.Scope::$watchText = (expression, callback, config) ->
        config = config or {}
        scope = @
        if alight.debug.watchText
            console.log '$watchText', expression

        # test simple text
        st = alight.utilits.compile.buildSimpleText expression, null
        if st
            return scope.$watch expression, callback,
                watchText: st
                init: config.init

        data = alight.utilits.parsText expression

        watchCount = 0
        canUseObserver = true
        canUseSimpleBuilder = true
        noCache = false

        doUpdate = doFinally = ->

        for d in data # { type list value }
            if d.type is 'expression'

                # check for a text directive
                exp = d.list.join ' | '
                if exp[0] is '='
                    exp = '#bindonce ' + exp[1..]
                else if exp[0..1] is '::'
                    exp = '#oneTimeBinding ' + exp[2..]

                if exp[0] is '#'
                    alight.text.$base
                        exp: exp
                        scope: scope
                        point: d
                        update: ->
                            doUpdate()
                        finally: ->
                            doUpdate()
                            doFinally()
                    noCache = true
                    if d.type isnt 'text'
                        watchCount++
                        canUseObserver = false
                        canUseSimpleBuilder = false
                else
                    pe = alight.utils.parsExpression exp
                    if pe.isSimple
                        ce = scope.$compile pe.expression,
                            string: true
                            full: true
                            rawExpression: true
                            noBind: true

                        d.fn = ce.fn
                        if not ce.rawExpression
                            throw 'Error'
                        if ce.isSimple and ce.simpleVariables.length is 0  # static expression
                            d.type = 'text'
                            d.value = d.fn()
                        else
                            d.re = ce.rawExpression
                            if ce.isSimple > 1
                                d.simpleVariables = ce.simpleVariables
                            else
                                canUseObserver = false
                            watchCount++
                    else
                        watchCount++
                        canUseObserver = false
                        canUseSimpleBuilder = false
                        do (d) ->
                            scope.$watch exp, (value) ->
                                `if(value == null) value = ''`
                                d.value = value
                                doUpdate()
                            ,
                                init: true

        if not watchCount
            # static text
            value = ''
            for d in data
                value += d.value
            if config.init
                callback value
            return {
                isStatic: true
                value: value
                fire: ->
                    callback value
            }

        if canUseObserver
            if noCache
                st = alight.utilits.compile.buildSimpleText null, data
            else
                st = alight.utilits.compile.buildSimpleText expression, data
            return scope.$watch expression, callback,
                watchText: st
                init: config.init
        if canUseSimpleBuilder
            if noCache
                st = alight.utilits.compile.buildSimpleText null, data
            else
                st = alight.utilits.compile.buildSimpleText expression, data
            return scope.$watch expression, callback,
                watchText:
                    fn: st.fn
                init: config.init

        w = null
        key = getId()
        data.scope = scope
        fn = alight.utilits.compile.buildText expression, data
        doUpdate = ->
            scope.$system.root.private[key] = fn()
        doFinally = ->
            i = true
            for d in data
                if d.type is 'expression'
                    i = false
                    break
            if not i
                return
            scope.$watch '$finishScanOnce', ->
                w.stop()
            if config.onStatic
                config.onStatic()
        doUpdate()
        w = scope.$watch key, callback,
            private: true
            init: config.init
