
Test('scope root #0', 'scope-root-0').run ($test, alight) ->
    $test.start 24

    c0 = 0
    c1 = 0
    c2 = 0
    c3 = 0

    scope =
        name: 'linux'
    root = alight.ChangeDetector scope

    child = alight.ChangeDetector
        $parent: scope

    # attach parent
    root.watch '$destroy', ->
        child.destroy()
    child.$parent = root

    child.$parent.watch 'name', ->
        c0 += 1
    child.watch '$parent.name', ->
        c1 += 1
    child.watch 'ex', ->
        c2 += 1
    child.watch '$destroy', ->
        c3 += 1

    root.scan()
    child.scan()

    $test.equal c0, 0
    $test.equal c1, 0
    $test.equal c2, 0
    $test.equal c3, 0

    scope.name = 'ubuntu'
    root.scan()
    $test.equal c0, 1
    $test.equal c1, 0
    $test.equal c2, 0
    $test.equal c3, 0

    child.scan()
    $test.equal c0, 1
    $test.equal c1, 1
    $test.equal c2, 0
    $test.equal c3, 0

    child.scope.ex = 5
    root.scan()
    child.scan()
    $test.equal c0, 1
    $test.equal c1, 1
    $test.equal c2, 1, '15'
    $test.equal c3, 0

    root.destroy()
    $test.equal c0, 1
    $test.equal c1, 1
    $test.equal c2, 1
    $test.equal c3, 1

    scope.name = 'macos'
    root.scan()
    child.scan()
    $test.equal c0, 1
    $test.equal c1, 1
    $test.equal c2, 1
    $test.equal c3, 1

    $test.close()
