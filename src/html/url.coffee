
alight.d.al.html.modifier.url = (self) ->
    self.updateDom = (url) ->
        if not url
            self.removeBlock()
            return
        self.loadHtml
            cache: true
            url: url
            success: (html) ->
                self.removeBlock()
                self.insertBlock html
                return
            error: self.removeBlock
        return
