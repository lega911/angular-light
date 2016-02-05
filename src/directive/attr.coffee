
# al-attr:disabled="value"

do ->
    alight.hooks.attribute.unshift
        code: 'events'
        fn: ->
            d = @.attrName.match /^\:([\w\.]+)$/
            if not d
                return

            @.ns = 'al'
            @.name = 'attr'
            @.attrArgument = d[1]
            return

    props =
        checked: 'checked'
        readonly: 'readOnly'  # camel case
        value: 'value'
        selected: 'selected'
        muted: 'muted'
        disabled: 'disabled'

    alight.d.al.attr = (scope, element, key, env) ->
        d = env.attrArgument.split '.'
        attrName = d[0]
        prop = props[attrName]
        isTemplate = d.indexOf('tpl') > 0

        setter = (value) ->
            if prop
                element[prop] = if value? then value else ''
            else
                if value?
                    element.setAttribute attrName, value
                else
                    element.removeAttribute attrName

        if isTemplate
            scope.$watchText key, setter
        else
            scope.$watch key, setter
