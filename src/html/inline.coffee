
alight.d.al.html.modifier.inline = (self, option) ->
    originalPrepare = self.prepare
    self.prepare = ->
        originalPrepare()
        option.env.setValue self.name, self.baseElement.innerHTML
