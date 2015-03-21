
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


        expressin points
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

        dir env.setter, exp, conf.scope, env
            

    alight.Scope::$watchText = (expression, callback, config) ->
        config = config or {}
        scope = @
        if alight.debug.watchText
            console.log '$watchText', expression

        data = alight.utilits.parsText expression

        watchCount = 0
        canUseObserver = true
        canUseSimpleBuilder = true
        hasDirectives = false
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
                        hasDirectives = true
                        canUseObserver = false
                        canUseSimpleBuilder = false
                else
                    ce = scope.$compile exp,
                        string: true
                        full: true
                        rawExpression: true
                        noBind: true

                    d.fn = ce.fn
                    if ce.rawExpression
                        d.re = ce.rawExpression
                        if ce.isSimple > 1
                            d.simpleVariables = ce.simpleVariables
                        else
                            canUseObserver = false
                    else
                        canUseObserver = false
                        canUseSimpleBuilder = false
                    watchCount++

        if not watchCount
            # static text
            value = ''
            for d in data
                value += d.value
            return {
                isStatic: true
                value: value
            }

        if canUseObserver
            if noCache
                st = alight.utilits.compile.buildSimpleText null, data
            else
                st = alight.utilits.compile.buildSimpleText expression, data
            return scope.$watch expression, callback,
                watchText: st
        if canUseSimpleBuilder
            if noCache
                st = alight.utilits.compile.buildSimpleText null, data
            else
                st = alight.utilits.compile.buildSimpleText expression, data
            return scope.$watch expression, callback,
                watchText:
                    fn: st.fn
        if not hasDirectives
            data.scope = scope
            fn = alight.utilits.compile.buildText expression, data
            return scope.$watch expression, callback,
                watchText:
                    fn: fn

        w = null
        key = getId()
        data.scope = scope
        fn = alight.utilits.compile.buildText expression, data
        doUpdate = ->
            scope.$system.private[key] = fn()
        doFinally = ->
            i = true
            for d in data
                if d.type is 'expression'
                    i = false
                    break
            if not i
                return
            scope.$scan ->
                w.stop()
            if config.onStatic
                config.onStatic()
        doUpdate()
        w = scope.$watch key, callback,
            private: true
