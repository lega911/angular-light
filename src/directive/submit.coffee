
alight.d.al.submit = (scope, element, name) ->
    self =
        callback: scope.$compile name,
            no_return: true
            input: ['$event']
        start: ->
            self.onDom()
            return
        onDom: ->
            f$.on element, 'submit', self.doCallback
            scope.$watch '$destroy', self.offDom
            return
        offDom: ->
            f$.off element, 'submit', self.doCallback
            return
        doCallback: (e) ->
            e.preventDefault()
            e.stopPropagation()
            try
                self.callback scope, e
            catch e
                alight.exceptionHandler e, 'al-submit, error in expression: ' + name,
                    name: name
                    scope: scope
                    element: element
            scope.$scan()
            return
