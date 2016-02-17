alight.hooks.attribute.unshift
    code: 'attribute A2'
    fn: ->
        d = @.attrName.match /^\[([\w\.\-]+)\]$/
        if not d
            return

        value = d[1]
        if value.split('.')[0] is 'html'
            @.name = 'html'
            value = value.substring 5
        else
            @.name = 'attr'
        @.ns = 'al'
        @.attrArgument = value
        return


alight.hooks.attribute.unshift
    code: 'events A2'
    fn: ->
        d = @.attrName.match /^\(([\w\.\-]+)\)$/
        if not d
            return

        @.ns = 'al'
        @.name = 'on'
        @.attrArgument = d[1]
        return
