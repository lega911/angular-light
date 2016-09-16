
alight.filters.filter = class F
    constructor: (exp, scope, env) ->
        that = @
        filterObject = null
        @.value = []

        @.doFiltering = ->
            e = filterObject
            if not e
                env.setValue that.value
                return null
            if typeof(e) is 'string'
                e =
                    __all: e
            else if typeof(e) isnt 'object'
                env.setValue that.value
                return null

            result = for r in that.value
                if typeof r is 'object'
                    f = true
                    if e.__all
                        f = false
                        a = e.__all.toLowerCase()
                        for k, v of r
                            if k is '$alite_id'
                                continue
                            if (''+v).toLowerCase().indexOf(a) >= 0
                                f = true
                                break
                        if not f
                            continue

                    for k, v of e
                        if k is '__all'
                            continue
                        if not v?
                            continue
                        a = r[k]
                        if not a?
                            f = false
                            break
                        if a isnt v and (''+a).toLowerCase().indexOf((''+v).toLowerCase()) < 0
                            f = false
                            break
                    if not f
                        continue
                    r
                else
                    if not e.__all
                        continue
                    a = e.__all.toLowerCase()
                    if (''+r).toLowerCase().indexOf(a) < 0
                        continue
                    r

            env.setValue result
            null

        scope.$watch exp, (input) ->
            filterObject = input
            that.doFiltering()
        ,
            deep: true

    onChange: (input) ->
        @.value = input
        @.doFiltering()
