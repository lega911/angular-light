
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
