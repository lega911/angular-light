
clickMaker = (event) ->
    priority: 10
    stopPropagation: true
    init: (element, name, scope, env) ->
        self =
            stopPropagation: @.stopPropagation
            callback: scope.$compile name,
                no_return: true
            start: ->
                self.onDom()
                self.stop = env.takeAttr 'al-click-stop'
            onDom: ->
                f$.on element, event, self.doCallback
                scope.$watch '$destroy', self.offDom
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
                    self.callback scope
                catch e
                    alight.exceptionHandler e, 'al-click, error in expression: ' + name,
                        name: name
                        scope: scope
                        element: element

                if self.stop and scope.$eval self.stop
                    e.preventDefault()
                    if self.stopPropagation
                        e.stopPropagation()

                scope.$scan()

alight.d.al.click = clickMaker 'click'
alight.d.al.dblclick = clickMaker 'dblclick'
