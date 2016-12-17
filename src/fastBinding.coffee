
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


alight.core.fastBinding = (bindResult) ->
    if not alight.option.fastBinding
        return
    if bindResult.directive or bindResult.hook or not bindResult.fb
        return
    new FastBinding bindResult


FastBinding = (bindResult) ->
    self = @
    source = []
    self.fastWatchFn = []
    path = []
    walk = (fb, deep) ->
        if fb.dir
            rel = pathToEl path
            for d in fb.dir
                source.push 's.dir(' + self.fastWatchFn.length + ', ' + rel + ');'
                self.fastWatchFn.push d

        if fb.attr
            for it in fb.attr
                text = it.value
                key = it.attrName

                rel = pathToEl path
                fn = compileText text
                rtext = text.replace(/"/g, '\\"').replace(/\n/g, '\\n')
                if fn
                    source.push 's.fw("' + rtext + '", ' + self.fastWatchFn.length + ', '+ rel + ', "' + key + '");'
                    self.fastWatchFn.push fn
                else
                    source.push "s.wt('#{rtext}', #{rel}, '#{key}');"

        if fb.text
            rel = pathToEl path
            fn = compileText fb.text
            rtext = fb.text.replace(/"/g, '\\"').replace(/\n/g, '\\n')
            if fn
                source.push 's.fw("' + rtext + '", ' + self.fastWatchFn.length + ', ' + rel + ');'
                self.fastWatchFn.push fn
            else
                source.push 's.wt("' + rtext + '", ' + rel + ');'

        if fb.children
            for it in fb.children
                path.length = deep + 1
                path[deep] = it.index
                walk it.fb, deep + 1
        null

    walk bindResult.fb, 0

    source = source.join '\n'
    self.resultFn = alight.utils.compile.Function 's', 'el', 'f$', source

    @


FastBinding::bind = (cd, element) ->
    @.currentCD = cd
    @.resultFn @, element, f$
    return

FastBinding::dir = (fnIndex, el) ->
    d = @.fastWatchFn[fnIndex]
    cd = @.currentCD
    env = new Env
        attrName: d.attrName
        attrArgument: d.attrArgument
        changeDetector: cd
    r = d.fb.call env, cd.scope, el, d.value, env
    if r and r.start
        r.start()
    null

FastBinding::fw = (text, fnIndex, element, attr) ->
    cd = @.currentCD
    fn = @.fastWatchFn[fnIndex]
    value = fn cd.locals
    
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


FastBinding::wt = (expression, element, attr) ->
    @.currentCD.watchText expression, null,
        element: element
        elementAttr: attr
    return
