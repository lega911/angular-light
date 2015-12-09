
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

    scope = alight.bootstrap dom[0],
        num: 15

    $test.equal dom.attr('attr'), '20'
    $test.equal dom.text(), 'Text 30'

    scope.num = 50
    scope.$scan ->
        $test.equal dom.attr('attr'), '20'
        $test.equal dom.text(), 'Text 30'
        $test.close()


Test('text-directive-0', 'text-directive-0').run ($test, alight, timeout) ->
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

    scope = alight.bootstrap dom[0],
        num: 15

    $test.equal dom.attr('attr'), 'Attr $'

    timeout.add 150, ->
        $test.equal dom.attr('attr'), 'Attr 16'

        scope.num = 50
        scope.$scan ->
            $test.equal dom.attr('attr'), 'Attr 16'

            timeout.add 150, ->
                $test.equal dom.attr('attr'), 'Attr 86'
                $test.close()


Test('text-directive-2', 'text-directive-2').run ($test, alight) ->
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

    result = result2 = null
    w = cd.watchText '{{a}} {{#test0 b}} {{#test0 0}}!', (value) ->
        result = value
    w2 = cd2.watchText '{{a}} {{#test0 b}} {{#test0 0}}!', (value) ->
        result2 = value

    cd.scan()
    $test.equal result, 'Hello world 0!'
    $test.equal result2, 'Hello inner:world inner:0!'
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


Test('one-time-binding-1', 'one-time-binding-1').run ($test, alight) ->
    $test.start 6

    scope = {}
    cd = alight.ChangeDetector scope
    value = null
    w = cd.watchText 'Hello {{::a}}!', (v) ->
        count++
        value = v
    count = 0

    steps = [
        ->
            ->
                $test.equal value, 'Hello !'
                $test.equal count, 1
                next()
        ->
            scope.a = 0
            ->
                $test.equal value, 'Hello 0!'
                $test.equal count, 2
                next()
        ->
            scope.a = 5
            ->
                $test.equal value, 'Hello 0!'
                $test.equal count, 2
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


Test('onetime-binding-2', 'onetime-binding-2').run ($test, alight, timeout) ->
    $test.start 6

    exp = 'a{{::a}}-b{{::b}}-c{{::c}}!'
    dom = document.createElement 'div'
    dom.innerHTML = "<div>#{exp}</div>::<div>#{exp}</div>"

    scope = alight.bootstrap dom

    result = ->
        ttGetText dom

    steps = [
        ->
            $test.equal scope.$scan().total, 8
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
                timeout.add 1, ->
                    $test.equal scope.$scan().total, 0
                    $test.close()
    ]

    step = 0
    next = ->
        s = steps[step]
        if not s
            return
        step++
        n = s()
        scope.$scan n

    next()


Test('one-time-binding-3', 'one-time-binding-3').run ($test, alight) ->
    $test.start 10

    exp = 'Hello {{::name}}!'

    scope = {}
    cd = alight.ChangeDetector scope
    v0 = null
    w = cd.watchText exp, (v) ->
        v0 = v

    cd1 = cd.new()
    v1 = null
    w = cd1.watchText exp, (v) ->
        v1 = v

    steps = [
        ->
            $test.equal cd.scan().total > 0, true
            $test.equal cd1.scan().total > 0, true
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


Test('text-directive-finally', 'text-directive-finally').run ($test, alight) ->
    env = null
    alight.text.test1 = (callback, text, cd, ienv) ->
        callback 'init'
        env = ienv

    $test.start 13
    dom = $ '<div>Text {{#test1}}</div>'
    
    scope = alight.Scope()

    scanCount = 0
    scope.$watch '$finishScan', ->
        scanCount++

    anyCount = 0
    scope.$watch '$any', ->
        anyCount++

    alight.bind scope, dom[0]

    $test.equal dom.text(), 'Text init'
    
    $test.equal scope.$scan().total, 1

    env.setter 'two'
    scope.$scan
        late: true
        callback: ->
            $test.equal scanCount, 3
            $test.equal anyCount, 2
            $test.equal dom.text(), 'Text two'

            env.setter 'three'
            scope.$scan
                late: true
                callback: ->
                    $test.equal scanCount, 4
                    $test.equal anyCount, 3
                    $test.equal dom.text(), 'Text three'

                    env.finally 'four'
                    setTimeout ->
                        $test.equal scanCount, 4
                        $test.equal anyCount, 3
                        $test.equal dom.text(), 'Text three'

                        scope.$scan
                            late: true
                            callback: ->
                                $test.equal dom.text(), 'Text four'
                                $test.equal scope.$scan().total, 0
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

    cd.scan()
    
    $test.equal value, 'Hello world!'
    $test.equal cd.scan().total, 0
    $test.close()
