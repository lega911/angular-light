

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

    $test.equal count, 1
    scope.two = 'two'
    cd.scan ->
        $test.equal result, 'one two'
        $test.equal count, 3

        scope.two = 'three'
        cd.scan ->
            $test.equal result, 'one three'
            $test.equal count, 5
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
Test('$watchText #2').run ($test, alight) ->
    $test.start 2
    cd = alight.ChangeDetector()
    w = cd.watchText 'Test static text', ->
    $test.equal w.value, 'Test static text'
    $test.equal w.isStatic, true

    $test.close()


Test('$watchText #3').run ($test, alight) ->
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


Test('$watchText #4').run ($test, alight) ->
    $test.start 2

    alight.filters.double = ->
        (v) ->
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


Test('$watchText #5', 'watch-text-5').run ($test, alight) ->
    $test.start 10

    el = $('<div>{{one}} {{two}}</div>')[0]
    scope =
        one: 'A'

    cd = alight.ChangeDetector scope
    alight.applyBindings cd, el

    count = 0
    cd.watch ->
        count++
        null
    , ->

    $test.equal count, 1
    $test.equal el.innerHTML, 'A '
    cd.scan ->
        $test.equal count, 2
        $test.equal el.innerHTML, 'A '

        scope.one = 'X'
        cd.scan ->
            $test.equal count, 3
            $test.equal el.innerHTML, 'X '

            scope.two = 'Y'
            cd.scan ->
                $test.equal count, 4
                $test.equal el.innerHTML, 'X Y'

                cd.scan ->
                    $test.equal count, 5
                    $test.equal el.innerHTML, 'X Y'
                    $test.close()


Test('$watchText #6', 'watch-text-6').run ($test, alight) ->
    $test.start 9
    
    scope = 
        data:
            name: 'linux'

    # static text
    result = null
    cd = alight.ChangeDetector scope
    cd.watchText 'static text', (value) ->
        result = value
    ,
        init: true
    $test.equal result, 'static text'

    result = null
    watch = cd.watchText 'linux ubuntu', (value) ->
        result = value
    $test.equal result, null
    watch.fire()
    $test.equal result, 'linux ubuntu'

    # static expression
    result = null
    cd.watchText '1{{"static"}}2', (value) ->
        result = value
    ,
        init: true
    $test.equal result, '1static2'

    result = null
    watch = cd.watchText '1{{"linux"}}2', (value) ->
        result = value
    $test.equal result, null
    watch.fire()
    $test.equal result, '1linux2'

    # expression
    result = null
    cd.watchText '1{{data.name}}2', (value) ->
        result = value
    ,
        init: true
    $test.equal result, '1linux2'

    result = null
    watch = cd.watchText '1{{data.name}}2', (value) ->
        result = value
    $test.equal result, null
    watch.fire()
    $test.equal result, '1linux2'

    $test.close()


Test('$watch #1', 'watch-1').run ($test, alight) ->
    $test.start 5

    cd = alight.ChangeDetector
        list: [1,2,3]

    count = 0
    counter = ->
        count++

    w0 = cd.watch 'list', counter,
        isArray: true

    $test.equal count, 0
    w0.fire()
    $test.equal count, 1

    w1 = cd.watch 'list', counter,
        isArray: true
    $test.equal count, 1
    w1.fire()
    $test.equal count, 2

    cd.scope.list.push 4
    cd.scan ->
        $test.equal count, 4

        $test.close()


Test('$watch static #0', 'watch-static-0').run ($test, alight) ->
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
    w0.fire()
    w1.fire()
    w2.fire()
    w3.fire()
    w4.fire()
    $test.equal counter, 5

    r = cd.scan()

    $test.equal r.total, 0
    $test.equal r.changes, 0

    $test.close()
