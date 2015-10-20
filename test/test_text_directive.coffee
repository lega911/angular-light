
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
    scope = alight.Scope()
    scope.num = 15

    alight.applyBindings scope, dom[0]

    $test.equal dom.attr('attr'), '20'
    $test.equal dom.text(), 'Text 30'

    scope.num = 50
    scope.$scan ->
        $test.equal dom.attr('attr'), '20'
        $test.equal dom.text(), 'Text 30'
        $test.close()


Test('text-directive', 'text-directive-0').run ($test, alight) ->
    $test.start 4

    alight.filters.minus = (exp, scope) ->
        delta = scope.$eval exp
        (value) ->
            value - delta

    alight.text.double = (callback, expression, scope) ->
        callback '$'
        scope.$watch expression, (value) ->
            setTimeout ->
                callback value + value
                scope.$scan()
            , 100

    dom = $ '<div attr="Attr {{#double num | minus:7 }}"></div>'
    scope = alight.Scope()
    scope.num = 15

    alight.applyBindings scope, dom[0]

    $test.check dom.attr('attr') is 'Attr $'

    setTimeout ->
        $test.check dom.attr('attr') is 'Attr $'

        scope.num = 50
        scope.$scan ->
            $test.check dom.attr('attr') is 'Attr $'

            setTimeout ->
                $test.check dom.attr('attr') is 'Attr 86'
                $test.close()
            , 150

    , 150


Test('text-directive #2').run ($test, alight) ->
    $test.start 2

    alight.text.test0 = (cb, exp, scope) ->
        cb scope.$eval exp

    scope = alight.Scope()
    child = scope.$new()
    child.$ns =
        text:
            test0: (cb, exp, scope) ->
                cb 'inner:' + scope.$eval exp

    scope.a = 'Hello'
    scope.b = 'world'
    w = scope.$watchText '{{a}} {{#test0 b}} {{#test0 0}}!', ->
    w2 = child.$watchText '{{a}} {{#test0 b}} {{#test0 0}}!', ->
    $test.equal w.value, 'Hello world 0!'
    $test.equal w2.value, 'Hello inner:world inner:0!'
    $test.close()


Test('oneTime binding #0').run ($test, alight) ->
    $test.start 6

    scope = alight.Scope()
    count = 0
    value = null
    scope.$watch '::a', (v) ->
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
        scope.$scan n

    next()


Test('oneTime binding #1', 'one-time-binding-1').run ($test, alight) ->
    $test.start 6

    scope = alight.Scope()
    value = null
    w = scope.$watchText 'Hello {{::a}}!', (v) ->
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
        scope.$scan n

    next()


Test('oneTime binding #2', 'onetime-binding-2').run ($test, alight) ->
    $test.start 6

    exp = 'a{{::a}}-b{{::b}}-c{{::c}}!'
    scope = alight.Scope()
    dom = document.createElement 'div'
    dom.innerHTML = "<div>#{exp}</div>::<div>#{exp}</div>"

    alight.applyBindings scope, dom

    result = ->
        alight.f$.text dom

    steps = [
        ->
            $test.equal dictLen(scope.$system.watchers), 5
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
                $test.equal dictLen(scope.$system.watchers), 0
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
    $test.close()


Test('oneTime binding #3').run ($test, alight) ->
    $test.start 10

    exp = 'Hello {{::name}}!'

    scope = alight.Scope()
    v0 = null
    w = scope.$watchText exp, (v) ->
        v0 = v
    v0 = w.value

    scope1 = scope.$new()
    v1 = null
    w = scope1.$watchText exp, (v) ->
        v1 = v
    v1 = w.value

    steps = [
        ->
            $test.equal dictLen(scope.$system.watchers), 2
            $test.equal dictLen(scope1.$system.watchers), 2
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
        scope.$scan n

    next()
    $test.equal dictLen(scope.$system.watchers), 0
    $test.equal dictLen(scope1.$system.watchers), 0
    $test.close()


Test('text-directive env.finally', 'text-directive-finally').run ($test, alight) ->
    env = null
    alight.text.test1 = (callback, text, scope, ienv) ->
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

    alight.applyBindings scope, dom[0]

    $test.equal dom.text(), 'Text init'
    
    $test.equal dictLen(scope.$system.watchers), 1

    env.setter 'two'
    scope.$scanAsync ->
        $test.equal scanCount, 1
        $test.equal anyCount, 1
        $test.equal dom.text(), 'Text two'

        env.setter 'three'
        scope.$scanAsync ->
            $test.equal scanCount, 2
            $test.equal anyCount, 2
            $test.equal dom.text(), 'Text three'

            env.finally 'four'
            setTimeout ->
                $test.equal scanCount, 2
                $test.equal anyCount, 2
                $test.equal dom.text(), 'Text three'

                scope.$scanAsync ->
                    $test.equal dom.text(), 'Text four'
                    $test.equal dictLen(scope.$system.watchers), 0
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
    ,
        init: true

    $test.equal value, 'Hello world!'
    $test.equal scope.$scan().total, 0
    $test.close()
