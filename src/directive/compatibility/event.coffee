
do ->
    for key in ['keydown', 'keypress', 'keyup', 'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseover', 'mouseup', 'focus', 'blur', 'change']
        do (key) ->
            alight.d.al[key] = (scope, element, exp, env) ->
                self =
                    start: ->
                        self.makeCaller()
                        self.onDom()
                        return
                    makeCaller: ->
                        self.caller = env.compile exp,
                            no_return: true
                            input: ['$event']
                        return
                    onDom: ->
                        f$.on element, key, self.callback
                        env.watch '$destroy', self.offDom
                        return
                    offDom: ->
                        f$.off element, key, self.callback
                        return
                    callback: (e) ->
                        try
                            self.caller scope, e
                        catch e
                            alight.exceptionHandler e, key + ', error in expression: ' + exp,
                                exp: exp
                                scope: scope
                                element: element
                        env.scan()
                        return
