
dictLen = (d) ->
    i = 0
    for k of d
        i++
    i

Test('bindonce').run ($test, alight) ->
    $test.start 4

    alight.filters.double = ->
        (value) ->
            value + value

    dom = $ '<div attr="{{= num + 5 }}">Text {{= num + num }}</div>'
    cd = alight.ChangeDetector
        num: 15

    alight.applyBindings cd, dom[0]

    $test.equal dom.attr('attr'), '20'
    $test.equal dom.text(), 'Text 30'

    cd.scope.num = 50
    cd.scan ->
        $test.equal dom.attr('attr'), '20'
        $test.equal dom.text(), 'Text 30'
        $test.close()


Test('text-directive', 'text-directive-0').run ($test, alight, timeout) ->
    $test.start 4

    alight.filters.minus = (exp, cd) ->
        delta = cd.eval exp
        (value) ->
            value - delta

    alight.text.double = (callback, expression, cd) ->
        callback '$'
        cd.watch expression, (value) ->
            timeout.add 100, ->
                callback value + value
                cd.scan()

    dom = $ '<div attr="Attr {{#double num | minus:7 }}"></div>'
    cd = alight.ChangeDetector
        num: 15

    alight.applyBindings cd, dom[0]

    $test.check dom.attr('attr') is 'Attr $'

    timeout.add 150, ->
        $test.check dom.attr('attr') is 'Attr $'

        cd.scope.num = 50
        cd.scan ->
            $test.check dom.attr('attr') is 'Attr $'

            timeout.add 150, ->
                $test.check dom.attr('attr') is 'Attr 86'
                $test.close()


Test('text-directive #2').run ($test, alight) ->
    $test.start 2

    alight.text.test0 = (callback, exp, cd) ->
        callback cd.eval exp

    Child = ->
    Child:: = scope = {}

    cd = alight.ChangeDetector scope
    cd2 = cd.new new Child()
    cd2.scope.$ns =
        text:
            test0: (callback, exp, cd) ->
                callback 'inner:' + cd.eval exp

    scope.a = 'Hello'
    scope.b = 'world'
    w = cd.watchText '{{a}} {{#test0 b}} {{#test0 0}}!', ->
    w2 = cd2.watchText '{{a}} {{#test0 b}} {{#test0 0}}!', ->
    $test.equal w.value, 'Hello world 0!'
    $test.equal w2.value, 'Hello inner:world inner:0!'
    $test.close()


Test('oneTime binding #0').run ($test, alight) ->
    $test.start 6

    scope = {}
    cd = alight.ChangeDetector scope
    count = 0
    value = null
    cd.watch '::a', (v) ->
        count++
        value = v

    steps = [
        ->
            ->
                $test.equal value, null
                $test.equal count, 0
                next()
        ->
            scope.a = 0
            ->
                $test.equal value, 0
                $test.equal count, 1
                next()
        ->
            scope.a = 5
            ->
                $test.equal value, 0
                $test.equal count, 1
                next()
        ->
            ->
                $test.close()
    ]

    step = 0
    next = ->
        s = steps[step]
        if not s
            return
        step++
        n = s()
        cd.scan n

    next()


Test('oneTime binding #1', 'one-time-binding-1').run ($test, alight) ->
    $test.start 6

    scope = {}
    cd = alight.ChangeDetector scope
    value = null
    w = cd.watchText 'Hello {{::a}}!', (v) ->
        count++
        value = v
    value = w.value
    count = 0

    steps = [
        ->
            ->
                $test.equal value, 'Hello !'
                $test.equal count, 0
                next()
        ->
            scope.a = 0
            ->
                $test.equal value, 'Hello 0!'
                $test.equal count, 1
                next()
        ->
            scope.a = 5
            ->
                $test.equal value, 'Hello 0!'
                $test.equal count, 1
                next()
        ->
            ->
                $test.close()
    ]

    step = 0
    next = ->
        s = steps[step]
        if not s
            return
        step++
        n = s()
        cd.scan n

    next()


Test('oneTime binding #2', 'onetime-binding-2').run ($test, alight) ->
    $test.start 6

    exp = 'a{{::a}}-b{{::b}}-c{{::c}}!'
    scope = {}
    cd = alight.ChangeDetector scope
    dom = document.createElement 'div'
    dom.innerHTML = "<div>#{exp}</div>::<div>#{exp}</div>"

    alight.applyBindings cd, dom

    result = ->
        alight.f$.text dom

    steps = [
        ->
            $test.equal cd.scan().total, 5
            $test.equal result(), 'a-b-c!::a-b-c!'
            scope.a = 3
            ->
                $test.equal result(), 'a3-b-c!::a3-b-c!'
                next()
        ->
            scope.a = 4
            scope.b = 'x'
            ->
                $test.equal result(), 'a3-bx-c!::a3-bx-c!'
                next()
        ->
            scope.a = 5
            scope.b = 'y'
            scope.c = '5'
            ->
                $test.equal result(), 'a3-bx-c5!::a3-bx-c5!'
                next()
        ->
            ->
                $test.equal cd.scan().total, 0
    ]

    step = 0
    next = ->
        s = steps[step]
        if not s
            return
        step++
        n = s()
        cd.scan n

    next()
    $test.close()


Test('oneTime binding #3', 'one-time-binding-3').run ($test, alight) ->
    $test.start 10

    exp = 'Hello {{::name}}!'

    scope = {}
    cd = alight.ChangeDetector scope
    v0 = null
    w = cd.watchText exp, (v) ->
        v0 = v
    v0 = w.value

    cd1 = cd.new()
    v1 = null
    w = cd1.watchText exp, (v) ->
        v1 = v
    v1 = w.value

    steps = [
        ->
            $test.equal !!cd.scan().total, true
            $test.equal !!cd1.scan().total, true
            $test.equal v0, 'Hello !'
            $test.equal v1, 'Hello !'
            scope.name = 'linux'
            ->
                $test.equal v0, 'Hello linux!'
                $test.equal v1, 'Hello linux!'
                next()
        ->
            scope.name = 'ubuntu'
            ->
                $test.equal v0, 'Hello linux!'
                $test.equal v1, 'Hello linux!'
                next()
    ]

    step = 0
    next = ->
        s = steps[step]
        if not s
            return
        step++
        n = s()
        cd.scan n

    next()
    $test.equal cd.scan().total, 0
    $test.equal cd1.scan().total, 0
    $test.close()


Test('text-directive env.finally', 'text-directive-finally').run ($test, alight) ->
    env = null
    alight.text.test1 = (callback, text, cd, ienv) ->
        callback 'init'
        env = ienv

    $test.start 13
    dom = $ '<div>Text {{#test1}}</div>'
    cd = alight.ChangeDetector()

    scanCount = 0
    cd.watch '$finishScan', ->
        scanCount++

    anyCount = 0
    cd.watch '$any', ->
        anyCount++

    alight.applyBindings cd, dom[0]

    $test.equal dom.text(), 'Text init'
    
    $test.equal cd.scan().total, 1

    env.setter 'two'
    cd.scan
        late: true
        callback: ->
            $test.equal scanCount, 2
            $test.equal anyCount, 1
            $test.equal dom.text(), 'Text two'

            env.setter 'three'
            cd.scan
                late: true
                callback: ->
                    $test.equal scanCount, 3
                    $test.equal anyCount, 2
                    $test.equal dom.text(), 'Text three'

                    env.finally 'four'
                    setTimeout ->
                        $test.equal scanCount, 3
                        $test.equal anyCount, 2
                        $test.equal dom.text(), 'Text three'

                        cd.scan
                            late: true
                            callback: ->
                                $test.equal dom.text(), 'Text four'
                                $test.equal cd.scan().total, 0
                                $test.close()
                    , 100


Test('oneTime binding #4', 'one-time-binding-4').run ($test, alight) ->
    $test.start 2

    exp = 'Hello {{::name}}!'

    cd = alight.ChangeDetector
        name: 'world'
    value = null
    cd.watchText exp, (v) ->
        value = v
    ,
        init: true

    $test.equal value, 'Hello world!'
    $test.equal cd.scan().total, 0
    $test.close()
