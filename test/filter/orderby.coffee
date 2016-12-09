
Test('filter-orderby-0').run ($test, alight) ->
    if not alight.filters.orderBy
        return 'skip'
    $test.start 4

    scope = {}
    scope.sortKey = 'name'
    scope.direct = true
    scope.list = []
    scope.list.push({name: '2 linux', k: 2, t: 1})
    scope.list.push({name: '5 windows', k: 5, t: 2})
    scope.list.push({name: '3 macos', k: 3, t: 3})
    scope.list.push({name: '4 unix', k: 4, t: 4})
    scope.list.push({name: '1 ubuntu', k: 1, t: 5})
    scope.list.push({name: '6 freebsd', k: 6, t: 6})

    result = null
    cd = alight.ChangeDetector scope
    cd.watch "list | orderBy:sortKey,direct", (value) ->
        result = value

    r = ->
        res = ''
        for i in result
            res += '' + i.k
        res

    cd.scan()
    $test.equal r(), '123456'

    scope.direct = false
    cd.scan()
    $test.equal r(), '654321'

    scope.sortKey = 't'
    cd.scan()
    $test.equal r(), '614352'

    scope.direct = true
    cd.scan()
    $test.equal r(), '253416'

    $test.close()
