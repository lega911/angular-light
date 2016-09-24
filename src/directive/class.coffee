
# al-css="class:exp"
alight.d.al.class = alight.d.al.css = (scope, element, exp, env) ->
    self =
        start: ->
            self.parsLine()
            self.prepare()
            return
        parsLine: ->
            self.list = list = []

            for e in exp.split ','
                i = e.indexOf ':'
                if i < 0
                    alight.exceptionHandler e, 'al-css, error in expression: ' + exp,
                        exp: exp
                        e: e
                        scope: scope
                        element: element
                else
                    list.push
                        css: e[0..i-1].trim().split ' '
                        exp: e[i+1..].trim()
            return
        prepare: ->
            for item in self.list
                color = do (item) ->
                    (value) ->
                        self.draw item, value
                        '$scanNoChanges'

                env.watch item.exp, color
            return
        draw: (item, value) ->
            if value
                for c in item.css
                    f$.addClass element, c
            else
                for c in item.css
                    f$.removeClass element, c
            return
