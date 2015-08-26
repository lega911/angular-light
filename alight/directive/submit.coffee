
alight.d.al.submit = (element, name, scope) ->
    self =
        callback: scope.$compile name,
            no_return: true
        start: ->
            self.onDom()
        onDom: ->
            f$.on element, 'submit', self.doCallback
            scope.$watch '$destroy', self.offDom
        offDom: ->
            f$.off element, 'submit', self.doCallback
        doCallback: (e) ->
            e.preventDefault()
            e.stopPropagation()
            try
                self.callback scope
            catch e
                alight.exceptionHandler e, 'al-submit, error in expression: ' + name,
                    name: name
                    scope: scope
                    element: element
            scope.$scan()
