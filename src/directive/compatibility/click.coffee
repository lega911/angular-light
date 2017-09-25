
clickMaker = (event) ->
    priority: 10
    stopPropagation: true
    link: (scope, element, name, env) ->
        self =
            stopPropagation: @.stopPropagation
            callback: env.compile name,
                no_return: true
                input: ['$event']
            start: ->
                self.onDom()
                self.stop = env.takeAttr 'al-click-stop'
                return
            onDom: ->
                f$.on element, event, self.doCallback
                env.watch '$destroy', self.offDom
                return
            offDom: ->
                f$.off element, event, self.doCallback
                return
            doCallback: (e) ->
                if not self.stop
                    e.preventDefault()
                    if self.stopPropagation
                        e.stopPropagation()

                if element.getAttribute 'disabled'
                    return

                try
                    self.callback scope, e
                catch e
                    alight.exceptionHandler e, 'al-click, error in expression: ' + name,
                        name: name
                        scope: scope
                        element: element

                if self.stop and env.eval self.stop
                    e.preventDefault()
                    if self.stopPropagation
                        e.stopPropagation()

                env.scan()
                return

alight.d.al.click = clickMaker 'click'
alight.d.al.dblclick = clickMaker 'dblclick'
