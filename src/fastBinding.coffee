
pathToEl = (path) ->
    if not path.length
        return 'el'

    result = 'el'
    for i in path
        result += ".childNodes[#{i}]"
    result


compileText = (text) ->
    data = alight.utils.parsText text
    for d in data
        if d.type isnt 'expression'
            continue

        if d.list.length > 1  # has filters
            return null

        key = d.list[0]
        if key[0] is '#'
            return null
        if key[0] is '='
            return null
        if key[0..1] is '::'
            return null

        ce = alight.utils.compile.expression key,
            string: true

        if not ce.rawExpression
            throw 'Error'
        d.re = ce.rawExpression

    st = alight.utils.compile.buildSimpleText text, data
    st.fn


alight.core.fastBinding = fastBinding = (element) ->
    self = @
    source = []
    self.fastWatchFn = []
    path = []
    walk = (element, deep) ->
        if element.nodeType is 1
            # attributes
            for attr in element.attributes
                if attr.value.indexOf(alight.utils.pars_start_tag) < 0
                    continue

                text = attr.value
                key = attr.nodeName

                rel = pathToEl path
                fn = compileText text
                rtext = text.replace(/"/g, '\\"').replace(/\n/g, '\\n')
                if fn
                    source.push "s.fw('#{rtext}', #{self.fastWatchFn.length}, #{rel}, '#{key}');"
                    self.fastWatchFn.push fn
                else
                    source.push "s.wt('#{rtext}', #{rel}, '#{key}');"

            # child nodes
            for childElement, i in element.childNodes
                path.length = deep + 1
                path[deep] = i
                walk childElement, deep + 1
        else if element.nodeType is 3
            if element.nodeValue.indexOf(alight.utils.pars_start_tag) < 0
                return

            text = element.nodeValue

            rel = pathToEl path
            fn = compileText text
            rtext = text.replace(/"/g, '\\"').replace(/\n/g, '\\n')
            if fn
                source.push 's.fw("' + rtext + '", ' + self.fastWatchFn.length + ', ' + rel + ');'
                self.fastWatchFn.push fn
            else
                source.push 's.wt("' + rtext + '", ' + rel + ');'

        null

    walk element, 0

    source = source.join '\n'
    self.resultFn = alight.utils.compile.Function 's', 'el', 'f$', source

    @


fastBinding::bind = (cd, element) ->
    self = @
    self.currentCD = cd
    self.resultFn self, element, f$
    return

fastBinding::fw = (text, fnIndex, element, attr) ->
    self = @
    cd = self.currentCD
    fn = self.fastWatchFn[fnIndex]
    value = fn cd.scope
    
    w =
        isStatic: false
        isArray: false
        extraLoop: false
        deep: false
        value: value
        callback: null
        exp: fn
        src: text
        onStop: null
        el: element
        ea: attr or null
    cd.watchList.push w
    execWatchObject cd.scope, w, value
    return


fastBinding::wt = (expression, element, attr) ->
    @.currentCD.watchText expression, null,
        element: element
        elementAttr: attr
    return
