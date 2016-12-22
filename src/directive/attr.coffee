
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
        if not env.attrArgument
            return
        d = env.attrArgument.split '.'
        attrName = d[0]
        prop = props[attrName]
        isTemplate = d.indexOf('tpl') > 0

        if alight.option.removeAttribute
            element.removeAttribute env.attrName
            if env.fbElement
                env.fbElement.removeAttribute env.attrName

        args =
            readOnly: true
        setter = null

        if attrName is 'style'
            if not d[1]
                throw 'Style is not declared'
            styleName = d[1].replace /(-\w)/g, (m) ->
                m.substring(1).toUpperCase()
            setter = (element, value) ->
                if not value?
                    value = ''
                element.style[styleName] = value
        else if attrName is 'class' and d.length > 1
            isTemplate = false
            list = d.slice 1
            setter = (element, value) ->
                if value
                    for c in list
                        f$.addClass element, c
                else
                    for c in list
                        f$.removeClass element, c
                return
        else if attrName is 'focus'
            setter = (element, value) ->
                if value
                    element.focus()
                else
                    element.blur()
        else
            if prop
                setter = (element, value) ->
                    if value is undefined
                        value = null
                    if element[prop] isnt value
                        element[prop] = value
            else
                args.element = element
                args.elementAttr = attrName

        watch = if isTemplate then 'watchText' else 'watch'
        if setter
            fn = (scope, element, _, env) ->
                env.changeDetector[watch] key, (value) ->
                    setter element, value
                , args
        else
            fn = (scope, element, _, env) ->
                env.changeDetector[watch] key, null,
                    readOnly: true
                    element: element
                    elementAttr: attrName

        fn scope, element, key, env
        env.fastBinding = fn
        return
