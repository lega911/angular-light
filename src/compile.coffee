###
    src - expression
    cfg:
        scope
        hash        
        no_return   - method without return (exec)
        string      - method will return result as string
        input       - list of input arguments
        rawExpression

    return {
        fn
        rawExpression
        filters
        isSimple
        simpleVariables
    }

###

do ->
    alight.utils.compile = self = {}
    self.cache = {}


    self.Function = Function

    ###
    compile expression
        no_return
        input
        string

    return
        fn
        rawExpression

        result
        filters
        isSimple
        simpleVariables
        expression


    ###
    self.expression = (src, cfg) ->
        cfg = cfg or {}
        src = src.trim()
        hash = src + '#'
        hash += if cfg.no_return then '+' else '-'
        hash += if cfg.string then 's' else 'v'
        if cfg.input
            hash += cfg.input.join ','

        funcCache = self.cache[hash]
        if funcCache
            return funcCache

        funcCache = alight.utils.parsExpression src,
            input: cfg.input

        exp = funcCache.result
        no_return = cfg.no_return or false
        if no_return
            result = "var $$;#{exp}"
        else
            if cfg.string and not funcCache.filters
                result = "var $$, __ = (#{exp}); return '' + (__ || (__ == null?'':__))"
                funcCache.rawExpression = "(__=#{exp}) || (__ == null?'':__)"
            else
                result = "var $$;return (#{exp})"
        try
            if cfg.input
                args = cfg.input.slice()
                args.unshift '$$scope'
                args.push result
                fn = self.Function.apply null, args
            else
                fn = self.Function '$$scope', result
        catch e
            alight.exceptionHandler e, 'Wrong expression: ' + src,
                src: src
                cfg: cfg
            throw 'Wrong expression: ' + exp

        funcCache.fn = fn
        self.cache[hash] = funcCache


    self.cacheText = {}
    self.buildText = (text, data) ->
        fn = self.cacheText[text]
        if fn
            return ->
                fn.call data

        result = []
        for d, index in data
            if d.type is 'expression'
                if d.fn
                    result.push "this[#{index}].fn(this.scope)"
                else
                    # text directive
                    result.push "((x=this[#{index}].value) || (x == null?'':x))"
            else if d.value
                escapedValue = d.value
                    .replace(/\\/g, "\\\\")
                    .replace(/"/g, '\\"')
                    .replace(/\n/g, "\\n")
                result.push '"' + escapedValue + '"'
        result = result.join ' + '
        fn = self.Function "var x; return (#{result})"
        self.cacheText[text] = fn
        ->
            fn.call data


    self.cacheSimpleText = {}

    self.buildSimpleText = (text, data) ->
        item = if text then self.cacheSimpleText[text] else null
        if item or not data
            return item or null

        result = []
        simpleVariables = []
        for d, index in data
            if d.type is 'expression'
                result.push "(#{d.re})"
                if d.simpleVariables
                    simpleVariables.push.apply simpleVariables, d.simpleVariables
            else if d.value
                escapedValue = d.value
                    .replace(/\\/g, "\\\\")
                    .replace(/"/g, '\\"')
                    .replace(/\n/g, "\\n")
                result.push '"' + escapedValue + '"'
        result = result.join ' + '
        fn = self.Function '$$scope', "var $$, __; return (#{result})"
        item =
            fn: fn
            simpleVariables: simpleVariables
        if text
            self.cacheSimpleText[text] = item
        item
