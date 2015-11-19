
for key in ['keydown', 'keypress', 'keyup', 'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseover', 'mouseup', 'focus', 'blur', 'change']
    do (key) ->
        alight.d.al[key] = (cd, element, exp) ->
            self =
                start: ->
                    self.makeCaller()
                    self.onDom()
                makeCaller: ->
                    self.caller = cd.compile exp,
                        no_return: true
                        input: ['$event']
                onDom: ->
                    f$.on element, key, self.callback
                    cd.watch '$destroy', self.offDom
                offDom: ->
                    f$.off element, key, self.callback
                callback: (e) ->
                    try
                        self.caller cd.scope, e
                    catch e
                        alight.exceptionHandler e, key + ', error in expression: ' + exp,
                            exp: exp
                            cd: cd
                            scope: cd.scope
                            element: element
                    cd.scan()
