
Test('scope root #0', 'scope-root-0').run ($test, alight) ->
    $test.start 24

    c0 = 0
    c1 = 0
    c2 = 0
    c3 = 0

    scope = alight.Scope()
    scope.name = 'linux'

    child = scope.$new 'root'
    child.$parent.$watch 'name', ->
        c0 += 1
    child.$watch '$parent.name', ->
        c1 += 1
    child.$watch 'ex', ->
        c2 += 1
    child.$watch '$destroy', ->
        c3 += 1

    scope.$scan()
    child.$scan()

    $test.equal c0, 0
    $test.equal c1, 0
    $test.equal c2, 0
    $test.equal c3, 0

    scope.name = 'ubuntu'
    scope.$scan()
    $test.equal c0, 1
    $test.equal c1, 0
    $test.equal c2, 0
    $test.equal c3, 0

    child.$scan()
    $test.equal c0, 1
    $test.equal c1, 1
    $test.equal c2, 0
    $test.equal c3, 0

    child.ex = 5
    scope.$scan()
    child.$scan()
    $test.equal c0, 1
    $test.equal c1, 1
    $test.equal c2, 1
    $test.equal c3, 0

    scope.$destroy()
    $test.equal c0, 1
    $test.equal c1, 1
    $test.equal c2, 1
    $test.equal c3, 1

    scope.name = 'macos'
    scope.$scan()
    child.$scan()
    $test.equal c0, 1
    $test.equal c1, 1
    $test.equal c2, 1
    $test.equal c3, 1

    $test.close()
