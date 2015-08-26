
alight.d.al.radio =
    priority: 10
    init: (element, name, scope, env) ->
        watch = null
        self =
            changing: false
            start: ->
                self.makeValue()
                self.onDom()
                self.watchModel()
                self.initDom()
            makeValue: ->
                key = env.takeAttr 'al-value'
                if key
                    value = scope.$eval key
                else
                    value = env.takeAttr 'value'
                self.value = value
            onDom: ->
                f$.on element, 'change', self.updateModel
                scope.$watch '$destroy', self.offDom
            offDom: ->
                f$.off element, 'change', self.updateModel
            updateModel: ->
                self.changing = true
                scope.$setValue name, self.value
                scope.$scan ->
                    self.changing = false
            watchModel: ->
                watch = scope.$watch name, self.updateDom,
                    readOnly: true
            updateDom: (value) ->
                if self.changing
                    return
                f$.prop element, 'checked', value is self.value
            initDom: ->
                watch.fire()
