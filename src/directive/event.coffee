
for key in ['keydown', 'keypress', 'keyup', 'mousedown', 'mouseenter', 'mouseleave', 'mousemove', 'mouseover', 'mouseup', 'focus', 'blur', 'change']
    do (key) ->
        alight.d.al[key] = (scope, element, exp) ->
            self =
                start: ->
                    self.makeCaller()
                    self.onDom()
                makeCaller: ->
                    self.caller = scope.$compile exp,
                        no_return: true
                        input: ['$event']
                onDom: ->
                    f$.on element, key, self.callback
                    scope.$watch '$destroy', self.offDom
                offDom: ->
                    f$.off element, key, self.callback
                callback: (e) ->
                    try
                        self.caller scope, e
                    catch e
                        alight.exceptionHandler e, key + ', error in expression: ' + exp,
                            exp: exp
                            scope: scope
                            element: element
                    scope.$scan()
