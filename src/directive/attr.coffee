
# al-attr:disabled="value"

do ->
    alight.hooks.attribute.unshift
        code: 'attribute'
        fn: ->
            d = @.attrName.match /^\:([\w\.\-]+)$/
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

    props =
        checked: 'checked'
        readonly: 'readOnly'  # camel case
        value: 'value'
        selected: 'selected'
        muted: 'muted'
        disabled: 'disabled'
        hidden: 'hidden'

    alight.d.al.attr = (scope, element, key, env) ->
        env.fastBinding = true
        if not env.attrArgument
            return
        d = env.attrArgument.split '.'
        attrName = d[0]
        prop = props[attrName]
        isTemplate = d.indexOf('tpl') > 0

        args =
            readOnly: true

        if attrName is 'style'
            if not d[1]
                throw 'Need to define a style attribute'
            styleName = d[1].replace /(-\w)/g, (m) ->
                m.substring(1).toUpperCase()
            setter = (value) ->
                if not value?
                    value = ''
                element.style[styleName] = value
        else if attrName is 'focus'
            setter = (value) ->
                if value
                    element.focus()
                else
                    element.blur()
        else
            if prop
                setter = (value) ->
                    if prop
                        if value is undefined
                            value = null
                        if element[prop] isnt value
                            element[prop] = value
            else
                args.element = element
                args.elementAttr = attrName

        if isTemplate
            env.changeDetector.watchText key, setter, args
        else
            env.changeDetector.watch key, setter, args
