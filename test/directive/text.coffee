
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


Test('text-directive-0').run ($test, alight, timeout) ->
    $test.start 4

    alight.filters.minus = class
        constructor: (exp, scope) ->
            @.delta = scope.$eval exp
        onChange: (value) ->
            @.setValue value - @.delta

    alight.text.double = (callback, expression, scope) ->
        callback '$'
        scope.$watch expression, (value) ->
            timeout.add 100, ->
                callback value + value
                scope.$scan()

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

    alight.text.test0 = (callback, exp, scope) ->
        callback scope.$eval exp

    scope = alight.Scope()
    scope2 = alight.Scope()
    scope2.$ns =
        text:
            test0: (callback, exp, scope) ->
                callback 'inner:' + scope.$eval exp

    scope.a = 'Hello'
    scope.b = 'world'
    scope2.a = 'Hello'
    scope2.b = 'world'

    result = result2 = null
    scope.$watchText '{{a}} {{#test0 b}} {{#test0 0}}!', (value) ->
        result = value
    scope2.$watchText '{{a}} {{#test0 b}} {{#test0 0}}!', (value) ->
        result2 = value

    scope.$scan()
    scope2.$scan()
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

    scope = alight.Scope()
    value = null
    scope.$watchText 'Hello {{::a}}!', (v) ->
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
        scope.$scan n

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
            $test.equal scope.$scan().total, 6
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

    scope = alight.Scope()
    cd = scope.$rootChangeDetector
    v0 = null
    cd.watchText exp, (v) ->
        v0 = v

    cd1 = cd.new()
    v1 = null
    cd1.watchText exp, (v) ->
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


Test('text-directive-finally').run ($test, alight) ->
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

    $test.equal scope.$scan().total, 0

    env.setter 'two'
    scope.$scan
        late: true
        callback: ->
            $test.equal scanCount, 2
            $test.equal anyCount, 0
            $test.equal dom.text(), 'Text two'

            env.setter 'three'
            scope.$scan
                late: true
                callback: ->
                    $test.equal scanCount, 3
                    $test.equal anyCount, 0
                    $test.equal dom.text(), 'Text three'

                    env.finally 'four'
                    setTimeout ->
                        $test.equal scanCount, 3
                        $test.equal anyCount, 0
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

    scope = alight.Scope()
    scope.name = 'world'
    value = null
    scope.$watchText exp, (v) ->
        value = v

    scope.$scan()

    $test.equal value, 'Hello world!'
    $test.equal scope.$scan().total, 0
    $test.close()


Test('text-dir-no-watch-0').run ($test, alight) ->
    $test.start 13

    el = ttDOM '<div> a-{{#dir text}}-b-{{value}}</div>'

    setter = null
    finallyFn = null
    alight.text.dir = (callback, expression, scope, env) ->
        setter = callback
        finallyFn = env.finally

        setter 'first'

    scope = alight.Scope()
    scope.value = 'watch'
    alight.bind scope, el

    r = scope.$scan()

    $test.equal ttGetText(el), 'a-first-b-watch'
    $test.equal r.total, 2

    setter 'second'
    $test.equal ttGetText(el), 'a-first-b-watch'
    $test.equal r.total, 2

    r = scope.$scan()
    $test.equal ttGetText(el), 'a-second-b-watch'
    $test.equal r.total, 2

    # finally
    finallyFn 'third'
    $test.equal ttGetText(el), 'a-second-b-watch'
    $test.equal r.total, 2

    r = scope.$scan()
    $test.equal ttGetText(el), 'a-third-b-watch'
    $test.equal r.total, 2  # last time call for watch

    r = scope.$scan()
    $test.equal r.total, 2

    # test
    setter 'four'
    r = scope.$scan()
    $test.equal ttGetText(el), 'a-third-b-watch'
    $test.equal r.total, 2

    $test.close()


Test('text-dir-no-watch-1').run ($test, alight) ->
    $test.start 13

    el = ttDOM '<div> a-{{#dir text}}-b</div>'

    setter = null
    finallyFn = null
    alight.text.dir = (callback, expression, scope, env) ->
        setter = callback
        finallyFn = env.finally

        setter 'first'

    scope = alight.Scope()
    alight.bind scope, el

    r = scope.$scan()

    $test.equal ttGetText(el), 'a-first-b'
    $test.equal r.total, 0

    setter 'second'
    $test.equal ttGetText(el), 'a-first-b'
    $test.equal r.total, 0

    r = scope.$scan()
    $test.equal ttGetText(el), 'a-second-b'
    $test.equal r.total, 0

    # finally
    finallyFn 'third'
    $test.equal ttGetText(el), 'a-second-b'
    $test.equal r.total, 0

    r = scope.$scan()
    $test.equal ttGetText(el), 'a-third-b'
    $test.equal r.total, 0  # last time call for watch

    r = scope.$scan()
    $test.equal r.total, 0

    # test
    setter 'four'
    r = scope.$scan()
    $test.equal ttGetText(el), 'a-third-b'
    $test.equal r.total, 0

    $test.close()


Test('text-dir-no-watch-2').run ($test, alight) ->
    $test.start 4

    setter0 = null
    setter1 = null
    alight.text.dir0 = (callback, expression, scope, env) ->
        setter0 = callback

    alight.text.dir1 = (callback, expression, scope, env) ->
        setter1 = callback

    scope = alight.Scope()

    count = 0
    result = null
    scope.$watchText 'a-{{#dir0}}-{{#dir1}}-b', (value) ->
        result = value
        count++

    scope.$scan()

    $test.equal result, 'a---b'
    $test.equal count, 1

    setter0 'first'
    setter1 'second'
    setter0 'third'

    scope.$scan()
    $test.equal result, 'a-third-second-b'
    $test.equal count, 2

    $test.close()


Test('text-dir-no-watch-3').run ($test, alight) ->
    $test.start 4

    el = ttDOM '<div> a-{{#dir text}}-b</div>'

    setter = null
    alight.text.dir = (callback, expression, scope, env) ->
        setter = env.setterRaw

    scope = alight.Scope()
    alight.bind scope, el

    r = scope.$scan()
    $test.equal r.total, 0

    $test.equal ttGetText(el), 'a--b'

    setter 'first'
    $test.equal ttGetText(el), 'a-first-b'

    setter 'second'
    $test.equal ttGetText(el), 'a-second-b'

    $test.close()


Test('text-dir-no-watch-4').run ($test, alight) ->
    $test.start 5

    el = ttDOM '<div> a-{{#dir text}}-{{value}}-b</div>'

    setter = null
    alight.text.dir = (callback, expression, scope, env) ->
        setter = env.setterRaw

    scope = alight.Scope()
    scope.value = 'watch'
    alight.bind scope, el

    r = scope.$scan()
    $test.equal r.total, 2

    $test.equal ttGetText(el), 'a--watch-b'

    setter 'first'
    $test.equal ttGetText(el), 'a-first-watch-b'

    setter 'second'
    $test.equal ttGetText(el), 'a-second-watch-b'

    scope.value = 'new'
    scope.$scan()
    $test.equal ttGetText(el), 'a-second-new-b'

    $test.close()
