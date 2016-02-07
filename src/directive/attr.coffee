
# al-attr:disabled="value"

do ->
    alight.hooks.attribute.unshift
        code: 'attribute'
        fn: ->
            d = @.attrName.match /^\:([\w\.]+)$/
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

    alight.d.al.attr = (scope, element, key, env) ->
        if not env.attrArgument
            return
        d = env.attrArgument.split '.'
        attrName = d[0]
        prop = props[attrName]
        isTemplate = d.indexOf('tpl') > 0

        setter = (value) ->
            if prop
                if value is undefined
                    value = null
                if element[prop] isnt value
                    element[prop] = value
            else
                if value?
                    element.setAttribute attrName, value
                else
                    element.removeAttribute attrName

        if isTemplate
            scope.$watchText key, setter
        else
            scope.$watch key, setter
