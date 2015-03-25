
console.log 'test Core'

dictLen = (d) ->
    i = 0
    for k of d
        i++
    i

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
                $test.close()
        else
            $test.error()
            $test.close()


Test('$watch #2').run ($test, alight) ->
    $test.start 2
    scope = alight.Scope()
    scope.name = 'linux'

    w0 = scope.$watch 'name', ->
    w1 = scope.$watch 'name', ->

    $test.equal w0.value, 'linux'
    $test.equal w1.value, 'linux'
    $test.close()


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
                            $test.close()


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
                    $test.close()


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
    $test.close()


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
    $test.close()


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
        $test.close()


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
    $test.close()


Test('text-directive #2').run ($test, alight) ->
    $test.start 1

    alight.text.test0 = (cb, exp, scope) ->
        cb scope.$eval exp

    scope = alight.Scope()
    scope.a = 'Hello'
    scope.b = 'world'
    w = scope.$watchText '{{a}} {{#test0 b}} {{#test0 0}}!', ->
    $test.equal w.value, 'Hello world 0!'
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


Test('oneTime binding #2').run ($test, alight) ->
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
    $test.close()


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
    $test.close()


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
    
    $test.equal dictLen(scope.$system.watchers), 1

    env.setter 'two'
    scope.$scan ->
        $test.equal dom.text(), 'Text two'

        env.setter 'three'
        scope.$scan ->
            $test.equal dom.text(), 'Text three'

            env.finally 'four'
            scope.$scan ->
                $test.equal dom.text(), 'Text four'
                $test.equal dictLen(scope.$system.watchers), 0
                $test.close()


Test('deferred process').run ($test, alight) ->
    $test.start 7

    # mock ajax
    alight.f$.ajax = (cfg) ->
        setTimeout ->
            if cfg.url is 'testDeferredProcess'
                cfg.success "<p>{{name}}</p>"
            else
                cfg.error()
        , 100

    scope5 = scope3 = null

    alight.directives.ut =
        test5:
            templateUrl: 'testDeferredProcess'
            scope: true
            link: (el, name, scope) ->
                scope5 = scope
                scope.name = 'linux'
        test3:
            templateUrl: 'testDeferredProcess'
            link: (el, name, scope) ->
                scope3 = scope
                scope.name = 'linux'

    runOne = (template) ->
        root = alight.Scope()
        root.name = 'root'

        dom = document.createElement 'div'
        dom.innerHTML = template

        alight.applyBindings root, dom

        response =
            root: root
            html: ->
                dom.innerHTML.toLowerCase()
        response

    r0 = runOne '<span ut-test5="noop"></span>'
    r1 = runOne '<span ut-test3="noop"></span>'

    setTimeout ->
        # 0
        $test.equal alight.directives.ut.test5.template, undefined
        $test.equal r0.root.name, 'root'
        $test.equal scope5.name, 'linux'
        $test.equal r0.html(), '<span ut-test5="noop"><p>linux</p></span>'
        
        # 1
        $test.equal scope3, r1.root
        $test.equal r1.root.name, 'linux'
        $test.equal r1.html(), '<span ut-test3="noop"><p>linux</p></span>'
        
        $test.close()
    , 200



Test('html prefix-data').run ($test, alight) ->
    $test.start 3

    r = []
    alight.directives.al.test = (el, value) ->
        r.push value

    dom = $ '<div> <b al-test="one"></b> <b data-al-test="two"></b> </div>'
    scope = alight.Scope()

    alight.applyBindings scope, dom[0]

    $test.equal r[0], 'one'
    $test.equal r[1], 'two'
    $test.equal r.length, 2

    $test.close()


Test('$watch $any').run ($test, alight) ->
    $test.start 15
    scope = alight.Scope()
    scope.a = 1
    scope.b = 1

    countAny = 0
    countAny2 = 0
    countA = 0

    wa = scope.$watch '$any', ->
        countAny++

    scope.$watch '$any', ->
        countAny2++

    scope.$watch 'a', ->
        countA++

    $test.equal countA, 0
    $test.equal countAny, 0
    $test.equal countAny2, 0

    scope.b++
    scope.$scan ->
        $test.equal countA, 0
        $test.equal countAny, 0
        $test.equal countAny2, 0

        scope.a++
        scope.$scan ->
            $test.equal countA, 1
            $test.equal countAny, 1
            $test.equal countAny2, 1

            wa.stop()
            scope.a++
            scope.$scan ->
                $test.equal countA, 2
                $test.equal countAny, 1
                $test.equal countAny2, 2

                scope.$destroy()
                scope.a++
                scope.$scan ->
                    $test.equal countA, 2
                    $test.equal countAny, 1
                    $test.equal countAny2, 2

                    $test.close()


Test('$watch $finishScan').run ($test, alight) ->
    $test.start 8
    scope = alight.Scope()

    count0 = 0
    count1 = 0

    wa = scope.$watch '$finishScan', ->
        count0++
    scope.$watch '$finishScan', ->
        count1++

    $test.equal count0, 0
    $test.equal count1, 0
    scope.$scan()
    alight.nextTick ->
        $test.equal count0, 1
        $test.equal count1, 1

        wa.stop()
        scope.$scan()
        alight.nextTick ->
            $test.equal count0, 1
            $test.equal count1, 2

            scope.$destroy()
            scope.$scan()
            alight.nextTick ->
                $test.equal count0, 1
                $test.equal count1, 2

                $test.close()


Test('test dynamic read-only watch').run ($test, alight) ->
    $test.start 6
    scope = alight.Scope()
    scope.one = 'one'

    noop = ->
    result = null

    count = 0
    scope.$watch ->
        count++
        ''
    , noop,
        readOnly: true

    scope.$watch 'one', ->
        result

    $test.equal count, 1 # init
    scope.$scan ->
        $test.equal count, 2

        scope.one = 'two'
        scope.$scan ->
            $test.equal count, 4 # 2-loop

            scope.$scan ->
                $test.equal count, 5

                result = '$scanNoChanges'
                scope.one = 'three'
                scope.$scan ->
                    $test.equal count, 6
    
                    scope.$scan ->
                        $test.equal count, 7
                        $test.close()


Test('$watch private #0', 'watch-private-0').run ($test, alight) ->
    $test.start 8

    scope = alight.Scope()

    value = null
    count = 0
    scope.$watch 'key', (v) ->
        count++
        value = v
    ,
        private: true

    scope.$scan ->
        $test.equal count, 0
        $test.equal value, null

        scope.$system.root.private.key = 5
        scope.$scan ->
            $test.equal count, 1
            $test.equal value, 5

            scope.$system.root.private.key = 7
            scope.$scan ->
                $test.equal count, 2
                $test.equal value, 7

                root = scope.$system.root
                scope.$destroy()
                root.private.key = 11
                scope.$scan ->
                    $test.equal count, 2
                    $test.equal value, 7
                    root.private.key = 15
                    $test.close()


Test('$watch private #1', 'watch-private-1').run ($test, alight) ->
    if not alight.debug.useObserver
        return $test.close()
    $test.start 17

    _ob = []
    _unob = []
    alight.observer._objectObserve = (d, fn) ->
        _ob.push d
        Object.observe d, fn
    alight.observer._objectUnobserve = (d, fn) ->
        _unob.push d
        Object.unobserve d, fn
    #alight.observer._arrayObserve = Array.observe
    #alight.observer._arrayUnobserve = Array.unobserve

    scope = alight.Scope()

    value = null
    count = 0
    scope.$watch 'key', (v) ->
        count++
        value = v
    ,
        private: true

    fireCount = 0
    do ->
        p = scope.$system.root.privateOb
        fire = scope.$system.root.privateOb.fire
        scope.$system.root.privateOb.fire = (k, v) ->            
            fireCount++
            fire.call p, k, v

    scope.$scan ->
        $test.equal count, 0
        $test.equal value, null
        $test.equal fireCount, 0

        scope.$system.root.private.key = 5
        scope.$scan ->
            $test.equal count, 1
            $test.equal value, 5
            $test.equal fireCount, 1

            scope.$system.root.private.key = 7
            scope.$scan ->
                $test.equal count, 2
                $test.equal value, 7
                $test.equal fireCount, 2

                root = scope.$system.root
                scope.$destroy()
                root.private.key = 11
                scope.$scan ->
                    $test.equal count, 2
                    $test.equal value, 7
                    $test.equal fireCount, 2
                    root.private.key = 15

                    setTimeout ->
                        $test.equal fireCount, 2
                        $test.equal _ob.length, 2
                        $test.equal _unob.length, 2
                        $test.equal _unob.indexOf(_ob[0]) >= 0, true
                        $test.equal _unob.indexOf(_ob[1]) >= 0, true

                        $test.close()
                    , 100
