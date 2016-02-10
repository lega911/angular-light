
alight.d.al.html.modifier.id = (self) ->
    self.updateDom = (id) ->
        self.removeBlock()
        tpl = document.getElementById id
        if tpl
            html = tpl.innerHTML
            if html
                self.insertBlock html
        return
