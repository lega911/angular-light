
console.log 'test Core'

# test $watch
Test('$watch').run ($test, alight) ->
    $test.start 1
    scope = alight.Scope()
    scope.one = 'one'

    result = null
    w = scope.$watch 'one + " " + two', (value) ->
        result = value

    scope.two = 'two'
    scope.$scan ->
        if result is 'one two'
            w.stop()
            scope.two = '2'
            scope.$scan ->
                $test.check result is 'one two'
        else
            $test.error()


Test('$watch #2').run ($test, alight) ->
    $test.start 2
    scope = alight.Scope()
    scope.name = 'linux'

    w0 = scope.$watch 'name', ->
    w1 = scope.$watch 'name', ->

    $test.equal w0.value, 'linux'
    $test.equal w1.value, 'linux'


Test('$watchArray').run ($test, alight) ->
    $test.start 12
    scope = alight.Scope()
    #scope.list = null

    watch = 0
    watchArray = 0

    scope.$watch 'list', ->
        watch++
    scope.$watch 'list', ->
        watchArray++
    , true

    scope.$scan ->
        $test.equal watch, 0
        $test.equal watchArray, 0

        scope.list = [1, 2, 3]
        scope.$scan ->
            $test.equal watch, 1
            $test.equal watchArray, 1

            scope.list = [1, 2]
            scope.$scan ->
                $test.equal watch, 2  # watch should fire on objects, but filter generates new object every time, that create infinity loop
                $test.equal watchArray, 2

                scope.list.push(3)
                scope.$scan ->
                    $test.equal watch, 2
                    $test.equal watchArray, 3, 'list.push 3'

                    scope.$scan ->
                        $test.equal watch, 2
                        $test.equal watchArray, 3, 'none'

                        scope.list = 7
                        scope.$scan ->
                            $test.equal watch, 3
                            $test.equal watchArray, 4, 'list = 7'


Test('$watchArray#2').run ($test, alight) ->
    $test.start 4
    scope = alight.Scope()
    #scope.list = null

    watch = 0
    watchArray = 0

    scope.$watch 'list', ->
        watch++
    scope.$watch 'list', ->
        watchArray++
    , true

    scope.$scan ->
        $test.check watch is 0 and watchArray is 0
        scope.list = []
        scope.$scan ->
            $test.check watch is 1 and watchArray is 1

            scope.list = [1, 2, 3]
            scope.$scan ->
                $test.check watch is 2 and watchArray is 2

                scope.list.push(4)
                scope.$scan ->
                    $test.check watch is 2 and watchArray is 3


# test $watchText
Test('$watchText').run ($test, alight) ->
    $test.start 2
    scope = alight.Scope()
    scope.one = 'one'

    result = null
    scope.$watchText '{{one}} {{two}}', (value) ->
        result = value

    scope.two = 'two'
    scope.$scan ->
        $test.check result is 'one two'

        scope.two = 'three'
        scope.$scan ->
            $test.check result is 'one three'


# test filter
Test('filter').run ($test, alight) ->
    $test.start 2

    alight.filters.double = ->
        (value) ->
            value + value

    alight.filters.minus = (exp, scope) ->
        delta = scope.$eval exp
        (value) ->
            value - delta

    scope = alight.Scope()

    N = 15
    fn = ->
        N

    filter = alight.utilits.filterBuilder scope, fn, [' double ', ' minus:3']
    $test.check filter() is 27
    N = 50
    $test.check filter() is 97


Test('filter2').run ($test, alight) ->
    $test.start 2

    alight.filters.double = ->
        (value) ->
            value + value

    alight.filters.minus = (exp, scope) ->
        delta = scope.$eval exp
        (value) ->
            value - delta

    scope = alight.Scope()

    filter = alight.utilits.filterBuilder scope, null, [' double ', ' minus:3']
    $test.check filter(15) is 27
    $test.check filter(50) is 97


Test('binding').run ($test, alight) ->
    $test.start 2

    alight.filters.double = ->
        (value) ->
            value + value

    dom = $ '<div attr="{{ num + 5 }}">Text {{ num | double }}</div>'
    scope = alight.Scope()
    scope.num = 15

    alight.applyBindings scope, dom[0]

    $test.check dom.text() is 'Text 30' and dom.attr('attr') is '20'

    scope.num = 50
    scope.$scan ->
        $test.check dom.text() is 'Text 100' and dom.attr('attr') is '55'


Test('bindonce').run ($test, alight) ->
    $test.start 4

    alight.filters.double = ->
        (value) ->
            value + value

    dom = $ '<div attr="{{= num + 5 }}">Text {{= num | double }}</div>'
    scope = alight.Scope()
    scope.num = 15

    alight.applyBindings scope, dom[0]

    $test.equal dom.attr('attr'), '20'
    $test.equal dom.text(), 'Text 30'

    scope.num = 50
    scope.$scan ->
        $test.equal dom.attr('attr'), '20'
        $test.equal dom.text(), 'Text 30'


Test('text-directive').run ($test, alight) ->
    $test.start 4

    alight.filters.minus = (exp, scope) ->
        delta = scope.$eval exp
        (value) ->
            value - delta

    alight.text.double = (callback, expression, scope) ->
        callback 0
        scope.$watch expression, (value) ->
            setTimeout ->
                callback value + value
                scope.$scan()
            , 100

    dom = $ '<div attr="Attr {{#double num | minus:7 }}"></div>'
    scope = alight.Scope()
    scope.num = 15

    alight.applyBindings scope, dom[0]

    $test.check dom.attr('attr') is 'Attr -7'

    setTimeout ->
        $test.check dom.attr('attr') is 'Attr -7'

        scope.num = 50
        scope.$scan ->
            $test.check dom.attr('attr') is 'Attr -7'

            setTimeout ->
                $test.check dom.attr('attr') is 'Attr 93'
            , 150

    , 150


Test('test-take-attr').run ($test, alight) ->

    alight.directives.ut =
        test0:
            priority: 500
            init: (el, name, scope, env) ->
                $test.equal env.attributes[0].attrName, 'ut-test0'
                for attr in env.attributes
                    if attr.attrName is 'ut-text'
                        $test.equal attr.skip, true
                    if attr.attrName is 'ut-css'
                        $test.equal !!attr.skip, false
                $test.equal 'mo{{d}}el0', env.takeAttr 'ut-text'
                $test.equal 'mo{{d}}el1', env.takeAttr 'ut-css'

    $test.start 5
    dom = $ '<div ut-test0 ut-text="mo{{d}}el0" ut-css="mo{{d}}el1"></div>'

    scope = alight.Scope()

    alight.applyBindings scope, dom[0],
        skip_attr: ['ut-text']


Test('text-directive').run ($test, alight) ->
    $test.start 1

    alight.text.test0 = (cb, exp, scope) ->
        cb scope.$eval exp

    scope = alight.Scope()
    scope.a = 'Hello'
    scope.b = 'world'
    fn = scope.$compileText '{{a}} {{#test0 b}} {{#test0 0}}!'
    $test.equal fn(), 'Hello world 0!'


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


Test('oneTime binding #1').run ($test, alight) ->
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


Test('oneTime binding #2').run ($test, alight) ->
    $test.start 7

    exp = 'a{{::a}}-b{{::b}}-c{{::c}}!'
    scope = alight.Scope()
    dom = document.createElement 'div'
    dom.innerHTML = "<div>#{exp}</div>::<div>#{exp}</div>"

    alight.applyBindings scope, dom

    result = ->
        dom.innerText

    steps = [
        ->
            $test.equal !!scope.$system.watches[exp], true
            $test.equal scope.$system.watches[exp].callbacks.length, 2
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
                $test.equal !!scope.$system.watches[exp], false
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
            $test.equal !!scope.$system.watches[exp], true
            $test.equal !!scope1.$system.watches[exp], true
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
    $test.equal !!scope.$system.watches[exp], false
    $test.equal !!scope1.$system.watches[exp], false


Test('skipped attrs').run ($test, alight) ->
    $test.start 6

    activeAttr = (env) ->
        r = for i in env.attributes
            if i.skip
                continue
            i.attrName
        r.sort().join ','

    skippedAttr = (env) ->
        r = env.skippedAttr()
        r.sort().join ','

    alight.directives.ut =
        testAttr0:
            priority: 50
            init: (el, name, scope, env) ->
                $test.equal skippedAttr(env), 'ut-test-attr0,ut-two'
                $test.equal activeAttr(env), 'one,ut-test-attr1,ut-three'
                env.takeAttr 'ut-three'
                $test.equal skippedAttr(env), 'ut-test-attr0,ut-three,ut-two'
                $test.equal activeAttr(env), 'one,ut-test-attr1'

        testAttr1:
            priority: -50
            init: (el, name, scope, env) ->
                $test.equal skippedAttr(env), 'one,ut-test-attr0,ut-test-attr1,ut-three,ut-two'
                $test.equal activeAttr(env), ''

    scope = alight.Scope()
    dom = document.createElement 'div'
    dom.innerHTML = '<div one="1" ut-test-attr1 ut-test-attr0 ut-two ut-three></div>'
    element = dom.children[0]

    alight.applyBindings scope, element,
        skip_attr: ['ut-two']


Test('scope isolate').run ($test, alight) ->
    $test.start 6

    # usual
    scope = alight.Scope()
    scope.x = 5
    child = scope.$new()

    $test.equal child.x, 5
    scope.x = 7
    $test.equal child.x, 7

    # isolate
    scope = alight.Scope()
    scope.x = 5
    child = scope.$new true

    $test.equal child.x, undefined
    $test.equal child.$parent.x, 5
    scope.x = 7
    $test.equal child.x, undefined
    $test.equal child.$parent.x, 7


Test('text-directive env.finally').run ($test, alight) ->
    env = null
    alight.text.test1 = (callback, text, scope, ienv) ->
        callback 'init'
        env = ienv

    $test.start 6
    dom = $ '<div>Text {{#test1}}</div>'
    scope = alight.Scope()

    alight.applyBindings scope, dom[0]

    $test.equal dom.text(), 'Text init'
    $test.equal !!scope.$system.watches['Text {{#test1}}'], true

    env.setter 'two'
    scope.$scan ->
        $test.equal dom.text(), 'Text two'

        env.setter 'three'
        scope.$scan ->
            $test.equal dom.text(), 'Text three'

            env.finally 'four'
            scope.$scan ->
                $test.equal dom.text(), 'Text four'
                $test.equal !!scope.$system.watches['Text {{#test1}}'], false


Test('deferred process').run ($test, alight) ->
    $test.start 5

    # mock ajax
    Test.ajax = {}
    alight.f$.ajax = (cfg) ->
        setTimeout ->
            data = Test.ajax[cfg.url]
            if data
                cfg.success data
            else
                cfg.error
        , 100
    Test.ajax.testDeferredProcess = "<p>{{name}}</p>"

    rscope = alight.Scope()
    rscope.name = 'root'
    cscope = null

    alight.directives.ut =
        test5:
            templateUrl: 'testDeferredProcess'
            link: (el, name, scope) ->
                cscope = scope
                scope.name = 'linux'

    dom = document.createElement 'div'
    dom.innerHTML = '<span ut-test5></span>'

    alight.applyBindings rscope, dom

    setTimeout ->
        $test.equal rscope.name, 'root'
        $test.equal cscope.name, 'linux'
        $test.equal dom.innerHTML, '<span ut-test5=""><p>linux</p></span>'
        $test.equal alight.directives.ut.test5.template, undefined
        $test.equal alight.directives.ut.test5.scope, undefined
    , 200
