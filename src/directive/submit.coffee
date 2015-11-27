
alight.d.al.submit = (scope, cd, element, name) ->
    self =
        callback: cd.compile name,
            no_return: true
            input: ['$event']
        start: ->
            self.onDom()
        onDom: ->
            f$.on element, 'submit', self.doCallback
            cd.watch '$destroy', self.offDom
        offDom: ->
            f$.off element, 'submit', self.doCallback
        doCallback: (e) ->
            e.preventDefault()
            e.stopPropagation()
            try
                self.callback scope, e
            catch e
                alight.exceptionHandler e, 'al-submit, error in expression: ' + name,
                    name: name
                    cd: cd
                    scope: scope
                    element: element
            cd.scan()
