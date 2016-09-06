
Test('filter-stop-0').run ($test, alight) ->
    $test.start 3

    onstop = 0
    alight.filters.test =
        init: (scope, raw, env) ->
            onChange: (v) ->
                env.setValue v + '-' + v
            onStop: ->
                onstop += 1

    result = ''
    scope =
        name: 'linux'
    cd = alight.ChangeDetector scope
    cd.watch '::name | test', (value) ->
        result = value

    cd.scan ->
        $test.equal result, 'linux-linux'
        $test.equal onstop, 1

        r = cd.scan()
        $test.equal r.total, 0
        $test.close()


Test('filter-stop-1').run ($test, alight) ->
    $test.start 9

    init = 0
    change = 0
    stop = 0
    alight.filters.test =
        init: (scope, raw, env) ->
            init += 1
            onChange: (v) ->
                change += 1
                env.setValue v + '-' + v
            onStop: ->
                stop += 1

    result = ''
    scope = {}
    cd = alight.ChangeDetector scope
    cd.watch '::name | test', (value) ->
        result = value

    $test.equal result, ''
    $test.equal init, 1
    $test.equal change, 0
    $test.equal stop, 0

    cd.scan ->
        scope.name = 'linux'

        cd.scan ->
            $test.equal result, 'linux-linux'
            $test.equal init, 1
            $test.equal change, 1
            $test.equal stop, 1

            r = cd.scan()
            $test.equal r.total, 0
            $test.close()


Test('filter-stop-2').run ($test, alight) ->
    $test.start 2

    alight.filters.test = (value, prefix, col) ->
        prefix + (value * col)

    result = ''
    scope =
        value: 5

    cd = alight.ChangeDetector scope
    cd.watch 'value | test "hello", 2', (value) ->
        result = value

    cd.scan ->
        $test.equal result, 'hello10'

        r = cd.scan()
        $test.equal r.total, 1

        cd.destroy()
        $test.close()
