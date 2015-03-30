

# test $watchText
Test('$watchText #1', 'watch-text-1').run ($test, alight) ->
    $test.start 5
    scope = alight.Scope()
    scope.one = 'one'

    result = null
    scope.$watchText '{{one}} {{two}}', (value) ->
        result = value

    count = 0
    scope.$watch ->
        count++
        null
    , ->

    $test.equal count, 1
    scope.two = 'two'
    scope.$scan ->
        $test.equal result, 'one two'
        $test.equal count, 3

        scope.two = 'three'
        scope.$scan ->
            $test.equal result, 'one three'
            $test.equal count, 5
            $test.close()


Test('$watchText #1b').run ($test, alight) ->
    $test.start 2
    scope = alight.Scope()
    scope.data =
        one: 'one'

    result = null
    scope.$watchText '{{data.one}} {{data.two}}', (value) ->
        result = value

    scope.data.two = 'two'
    scope.$scan ->
        $test.check result is 'one two'

        scope.data.two = 'three'
        scope.$scan ->
            $test.check result is 'one three'
            $test.close()

# test $watchText
Test('$watchText #2').run ($test, alight) ->
    $test.start 2
    scope = alight.Scope()
    w = scope.$watchText 'Test static text', ->
    $test.equal w.value, 'Test static text'
    $test.equal w.isStatic, true

    $test.close()


Test('$watchText #3').run ($test, alight) ->
    $test.start 2
    scope = alight.Scope()
    scope.data =
        one: 'one'
    two = ''
    scope.fn = ->
        two

    result = null
    scope.$watchText '{{data.one}} {{fn()}}', (value) ->
        result = value

    two = 'two'
    scope.$scan ->
        $test.check result is 'one two'

        two = 'three'
        scope.$scan ->
            $test.check result is 'one three'
            $test.close()


Test('$watchText #4').run ($test, alight) ->
    $test.start 2

    alight.filters.double = ->
        (v) ->
            v+'-'+v

    scope = alight.Scope()
    scope.data =
        one: 'one'
    two = ''
    scope.fn = ->
        two

    result = null
    scope.$watchText '{{data.one}} {{fn() | double}}', (value) ->
        result = value

    two = 'two'
    scope.$scan ->
        $test.check result is 'one two-two'

        two = 'three'
        scope.$scan ->
            $test.check result is 'one three-three'
            $test.close()


Test('$watch $destroy', 'watch-destroy').run ($test, alight) ->
    $test.start 8

    s0 = alight.Scope()
    s1 = s0.$new()
    s0.$new()
    s2 = s1.$new()

    c1 = 0
    s1.$watch '$destroy', ->
        c1++
    c2 = 0
    s2.$watch '$destroy', ->
        c2++

    $test.equal c1, 0
    $test.equal c2, 0

    s2.$destroy()
    $test.equal c1, 0
    $test.equal c2, 1

    s0.$destroy()
    $test.equal c1, 1
    $test.equal c2, 1

    s2.$destroy()
    s1.$destroy()
    $test.equal c1, 1
    $test.equal c2, 1

    $test.close()


Test('$watchText #5', 'watch-text-5').run ($test, alight) ->
    $test.start 10

    el = $('<div>{{one}} {{two}}</div>')[0]
    scope = alight.Scope()
    scope.one = 'A'

    alight.applyBindings scope, el

    count = 0
    scope.$watch ->
        count++
        null
    , ->

    $test.equal count, 1
    $test.equal el.innerHTML, 'A '
    scope.$scan ->
        $test.equal count, 2
        $test.equal el.innerHTML, 'A '

        scope.one = 'X'
        scope.$scan ->
            $test.equal count, 3
            $test.equal el.innerHTML, 'X '

            scope.two = 'Y'
            scope.$scan ->
                $test.equal count, 4
                $test.equal el.innerHTML, 'X Y'

                scope.$scan ->
                    $test.equal count, 5
                    $test.equal el.innerHTML, 'X Y'
                    $test.close()
