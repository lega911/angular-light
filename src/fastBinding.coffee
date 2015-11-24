
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
            full: true
            rawExpression: true

        if not ce.rawExpression
            throw 'Error'
        d.re = ce.rawExpression

    st = alight.utils.compile.buildSimpleText text, data
    st.fn


alight.core.fastBinding = fastBinding = (element) ->
    self = @
    source = []
    self.fastWatchFn = []
    path = [0]
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
                rCallback = 'function(value) {f$.attr(' + rel + ', "' + key + '", value); return "$scanNoChanges"}'
                if fn
                    source.push 's.fw("' + rtext + '", ' + self.fastWatchFn.length + ', ' + rCallback + ');'
                    self.fastWatchFn.push fn
                else
                    source.push 's.wt("' + rtext + '", ' + rCallback + ');'

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
            rCallback = 'function(value) {' + rel + '.nodeValue=value; return "$scanNoChanges"}'
            if fn
                source.push 's.fw("' + rtext + '", ' + self.fastWatchFn.length + ', ' + rCallback + ');'
                self.fastWatchFn.push fn
            else
                source.push 's.wt("' + rtext + '", ' + rCallback + ');'

        null

    walk element, 0

    source = source.join '\n'
    self.resultFn = alight.utils.compile.Function 's', 'el', 'f$', source

    @


fastBinding::bind = (cd, element) ->
    self = @
    self.currentCD = cd
    self.resultFn self, element, f$
    null

fastBinding::fw = (text, fnIndex, callback) ->
    self = @
    cd = self.currentCD
    fn = self.fastWatchFn[fnIndex]
    value = fn cd.scope
    
    callback value
    cd.watchList.push
        isStatic: false
        isArray: false
        extraLoop: false
        deep: false
        value: value
        callback: callback
        exp: fn
        src: text
        onStop: null
    null


fastBinding::wt = (expression, callback) ->
    @.currentCD.watchText expression, callback,
        init: true
    @.currentCD.scan()  # require extra-loop
    null
