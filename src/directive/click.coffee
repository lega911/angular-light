
clickMaker = (event) ->
    priority: 10
    stopPropagation: true
    init: (node, element, name, env) ->
        self =
            stopPropagation: @.stopPropagation
            callback: node.compile name,
                no_return: true
                input: ['$event']
            start: ->
                self.onDom()
                self.stop = env.takeAttr 'al-click-stop'
            onDom: ->
                f$.on element, event, self.doCallback
                node.watch '$destroy', self.offDom
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
                    self.callback node.scope, e
                catch e
                    alight.exceptionHandler e, 'al-click, error in expression: ' + name,
                        name: name
                        node: node
                        element: element

                if self.stop and node.eval self.stop
                    e.preventDefault()
                    if self.stopPropagation
                        e.stopPropagation()

                node.scan()

alight.d.al.click = clickMaker 'click'
alight.d.al.dblclick = clickMaker 'dblclick'
