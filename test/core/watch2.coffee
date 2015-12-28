

# test $watchText
Test('$watchText #1', 'watch-text-1').run ($test, alight) ->
    $test.start 5
    scope =
        one: 'one'

    result = null
    cd = alight.ChangeDetector scope
    cd.watchText '{{one}} {{two}}', (value) ->
        result = value

    count = 0
    cd.watch ->
        count++
        null
    , ->

    $test.equal count, 0
    scope.two = 'two'
    cd.scan ->
        $test.equal result, 'one two'
        $test.equal count, 2

        scope.two = 'three'
        cd.scan ->
            $test.equal result, 'one three'
            $test.equal count, 4
            $test.close()


Test('$watchText #1b').run ($test, alight) ->
    $test.start 2
    scope =
        data:
            one: 'one'

    result = null
    cd = alight.ChangeDetector scope
    cd.watchText '{{data.one}} {{data.two}}', (value) ->
        result = value

    scope.data.two = 'two'
    cd.scan ->
        $test.check result is 'one two'

        scope.data.two = 'three'
        cd.scan ->
            $test.check result is 'one three'
            $test.close()

# test $watchText
Test('watch-text-static', 'watch-text-static').run ($test, alight) ->
    $test.start 3
    cd = alight.ChangeDetector()

    result = null
    count = 0

    cd.watchText 'Test static text', (value) ->
        result = value
        count++

    cd.scan()
    cd.scan()
    $test.equal result, 'Test static text'
    $test.equal count, 1
    $test.equal cd.scan().total, 0

    $test.close()


Test('watch-text-3').run ($test, alight) ->
    $test.start 2
    scope =
        data:
            one: 'one'
    two = ''
    scope.fn = ->
        two

    result = null
    cd = alight.ChangeDetector scope
    cd.watchText '{{data.one}} {{fn()}}', (value) ->
        result = value

    two = 'two'
    cd.scan ->
        $test.check result is 'one two'

        two = 'three'
        cd.scan ->
            $test.check result is 'one three'
            $test.close()


Test('watchtext-4').run ($test, alight) ->
    $test.start 2

    alight.filters.double = (v) ->
        v+'-'+v

    scope =
        data:
            one: 'one'

    two = ''
    scope.fn = ->
        two

    result = null
    cd = alight.ChangeDetector scope
    cd.watchText '{{data.one}} {{fn() | double}}', (value) ->
        result = value

    two = 'two'
    cd.scan ->
        $test.check result is 'one two-two'

        two = 'three'
        cd.scan ->
            $test.check result is 'one three-three'
            $test.close()


Test('$watch $destroy', 'watch-destroy').run ($test, alight) ->
    $test.start 8

    s0 = alight.ChangeDetector()
    s1 = s0.new()
    s0.new()
    s2 = s1.new()

    c1 = 0
    s1.watch '$destroy', ->
        c1++
    c2 = 0
    s2.watch '$destroy', ->
        c2++

    $test.equal c1, 0
    $test.equal c2, 0

    s2.destroy()
    $test.equal c1, 0
    $test.equal c2, 1

    s0.destroy()
    $test.equal c1, 1
    $test.equal c2, 1

    s2.destroy()
    s1.destroy()
    $test.equal c1, 1
    $test.equal c2, 1

    $test.close()


Test('watch-text-5', 'watch-text-5').run ($test, alight) ->
    $test.start 10

    el = ttDOM '<div>{{one}}-{{two}}</div>'

    scope = alight.bootstrap el,
        one: 'A'

    count = 0
    scope.$rootChangeDetector.watch ->
        count++
        null
    , ->

    $test.equal count, 0
    $test.equal ttGetText(el), 'A-'
    scope.$scan ->
        $test.equal count, 2
        $test.equal ttGetText(el), 'A-'

        scope.one = 'X'
        scope.$scan ->
            $test.equal count, 3
            $test.equal ttGetText(el), 'X-'

            scope.two = 'Y'
            scope.$scan ->
                $test.equal count, 4
                $test.equal ttGetText(el), 'X-Y'

                scope.$scan ->
                    $test.equal count, 5
                    $test.equal ttGetText(el), 'X-Y'
                    $test.close()


Test('watch-text-6').run ($test, alight) ->
    $test.start 9

    scope =
        data:
            name: 'linux'

    # static text
    result = null
    cd = alight.ChangeDetector scope
    cd.watchText 'static text', (value) ->
        result = value

    cd.scan()
    $test.equal result, 'static text'

    result = null
    watch = cd.watchText 'linux ubuntu', (value) ->
        result = value
    $test.equal result, null
    cd.scan()
    $test.equal result, 'linux ubuntu'

    # static expression
    result = null
    cd.watchText '1{{"static"}}2', (value) ->
        result = value
    cd.scan()
    $test.equal result, '1static2'

    result = null
    watch = cd.watchText '1{{"linux"}}2', (value) ->
        result = value
    $test.equal result, null
    cd.scan()
    $test.equal result, '1linux2'

    # expression
    result = null
    cd.watchText '1{{data.name}}2', (value) ->
        result = value

    cd.scan()
    $test.equal result, '1linux2'

    result = null
    watch = cd.watchText '1{{data.name}}2', (value) ->
        result = value
    $test.equal result, null
    cd.scan()
    $test.equal result, '1linux2'

    $test.close()


Test('watch-1', 'watch-1').run ($test, alight) ->
    $test.start 5

    cd = alight.ChangeDetector
        list: [1,2,3]

    count = 0
    counter = ->
        count++

    w0 = cd.watch 'list', counter,
        isArray: true

    $test.equal count, 0
    cd.scan()
    $test.equal count, 1

    w1 = cd.watch 'list', counter,
        isArray: true
    $test.equal count, 1
    cd.scan()
    $test.equal count, 2

    cd.scope.list.push 4
    cd.scan ->
        $test.equal count, 4

        $test.close()


Test('watch-static-0', 'watch-static-0').run ($test, alight) ->
    $test.start 4

    cd = alight.ChangeDetector
        name: 'linux'

    counter = 0
    w0 = cd.watch '"one"', ->
        counter += 1
    w1 = cd.watch '2', ->
        counter += 1
    w2 = cd.watch 'true', ->
        counter += 1
    w3 = cd.watch 'false', ->
        counter += 1
    w4 = cd.watch '5 + 5', ->
        counter += 1

    $test.equal counter, 0
    cd.scan()
    $test.equal counter, 5

    r = cd.scan()

    $test.equal r.total, 0
    $test.equal r.changes, 0

    $test.close()


Test('watch-static-1', 'watch-static-1').run ($test, alight) ->
    $test.start 1

    alight.filters.double = (x) ->
        x+x

    el = ttDOM '<div>{{"one" | double}}</div>'
    scope = alight.bootstrap el

    $test.equal ttGetText(el), 'oneone'

    $test.close()
