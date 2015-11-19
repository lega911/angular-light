
clickMaker = (event) ->
    priority: 10
    stopPropagation: true
    init: (cd, element, name, env) ->
        self =
            stopPropagation: @.stopPropagation
            callback: cd.compile name,
                no_return: true
                input: ['$event']
            start: ->
                self.onDom()
                self.stop = env.takeAttr 'al-click-stop'
            onDom: ->
                f$.on element, event, self.doCallback
                cd.watch '$destroy', self.offDom
            offDom: ->
                f$.off element, event, self.doCallback
            doCallback: (e) ->
                if not self.stop
                    e.preventDefault()
                    if self.stopPropagation
                        e.stopPropagation()

                if f$.attr element, 'disabled'
                    return

                try
                    self.callback cd.scope, e
                catch e
                    alight.exceptionHandler e, 'al-click, error in expression: ' + name,
                        name: name
                        cd: cd
                        scope: cd.scope
                        element: element

                if self.stop and cd.eval self.stop
                    e.preventDefault()
                    if self.stopPropagation
                        e.stopPropagation()

                cd.scan()

alight.d.al.click = clickMaker 'click'
alight.d.al.dblclick = clickMaker 'dblclick'
