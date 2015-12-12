
Test('binding-0').run ($test, alight) ->
    $test.start 4

    alight.filters.double = ->
        (value) ->
            value + value

    el = ttDOM '<div attr="{{ num + 5 }}">Text {{ num | double }}</div>'

    scope = alight.bootstrap el,
        num: 15

    $test.equal ttGetText(el), 'Text 30'
    $test.equal f$_attr(el.childNodes[0], 'attr'), '20'

    scope.num = 50
    scope.$scan ->
        $test.equal ttGetText(el), 'Text 100'
        $test.equal f$_attr(el.childNodes[0], 'attr'), '55'
        $test.close()


Test('test-take-attr').run ($test, alight) ->

    alight.directives.ut =
        test0:
            priority: 500
            init: (scope, el, name, env) ->
                $test.equal env.attributes[0].attrName, 'ut-test0'
                for attr in env.attributes
                    if attr.attrName is 'ut-text'
                        $test.equal attr.skip, true
                    if attr.attrName is 'ut-css'
                        $test.equal !!attr.skip, false
                $test.equal 'mo{{d}}el0', env.takeAttr 'ut-text'
                $test.equal 'mo{{d}}el1', env.takeAttr 'ut-css'

    $test.start 5
    el = ttDOM '<div ut-test0 ut-text="mo{{d}}el0" ut-css="mo{{d}}el1"></div>'

    scope = alight.Scope()

    alight.bind scope, el.childNodes[0],
        skip_attr: ['ut-text']
    $test.close()


Test('skipped-attrs-0').run ($test, alight) ->
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
            init: (scope, el, name, env) ->
                $test.equal skippedAttr(env), 'ut-test-attr0,ut-two'
                $test.equal activeAttr(env), 'one,ut-test-attr1,ut-three'
                env.takeAttr 'ut-three'
                $test.equal skippedAttr(env), 'ut-test-attr0,ut-three,ut-two'
                $test.equal activeAttr(env), 'one,ut-test-attr1'

        testAttr1:
            priority: -50
            init: (scope, el, name, env) ->
                $test.equal skippedAttr(env), 'one,ut-test-attr0,ut-test-attr1,ut-three,ut-two'
                $test.equal activeAttr(env), ''

    scope = alight.Scope()
    dom = document.createElement 'div'
    dom.innerHTML = '<div one="1" ut-test-attr1 ut-test-attr0 ut-two ut-three></div>'
    element = dom.children[0]

    alight.bind scope, element,
        skip_attr: ['ut-two']
    $test.close()


Test('deferred-process').run ($test, alight, timeout) ->
    $test.start 9

    # mock ajax
    alight.f$.ajax = (cfg) ->
        timeout.add 100, ->
            if cfg.url is 'testDeferredProcess'
                cfg.success "<p>{{name}}</p>"
            else
                cfg.error()

    scope5 = scope3 = null

    alight.directives.ut =
        test5:
            templateUrl: 'testDeferredProcess'
            scope: true
            link: (scope, el, name) ->
                scope.name = 'linux'
                scope5 = scope
        test3:
            templateUrl: 'testDeferredProcess'
            link: (scope, el, name) ->
                scope.name = 'linux'
                scope3 = scope

    runOne = (template) ->
        scope = alight.Scope()
        scope.name = 'root'

        dom = document.createElement 'div'
        dom.innerHTML = template

        alight.bind scope, dom

        response =
            scope: scope
            html: ->
                dom.innerHTML.toLowerCase()
        response

    r0 = runOne '<span ut-test5="noop"></span>'
    r1 = runOne '<span ut-test3="noop"></span>'

    timeout.add 200, ->
        # 0
        $test.equal alight.directives.ut.test5.template, undefined
        $test.equal r0.scope.name, 'root'
        $test.equal r0.scope.$rootChangeDetector.children[0].scope.name, 'linux'
        $test.equal scope5.name, 'linux'
        $test.equal r0.html(), '<span ut-test5="noop"><p>linux</p></span>'
        
        # 1
        $test.equal scope3, r1.scope
        $test.equal r1.scope.name, 'linux'
        $test.equal r1.scope.$rootChangeDetector.children.length, 0
        $test.equal r1.html(), '<span ut-test3="noop"><p>linux</p></span>'
        
        $test.close()


Test('html-prefix-data').run ($test, alight) ->
    $test.start 3

    r = []
    alight.directives.al.test = (scope, el, value) ->
        r.push value

    el = ttDOM '<div> <b al-test="one"></b> <b data-al-test="two"></b> </div>'
    alight.bind alight.Scope(), el.childNodes[0]

    $test.equal r[0], 'one'
    $test.equal r[1], 'two'
    $test.equal r.length, 2

    $test.close()


Test 'root-scope-access-to-parent'
    .run ($test, alight) ->
        $test.start 2

        alight.d.al.test =
            scope: 'root'
            link: (scope, el, key, env) ->
                env.parentChangeDetector.watch key, (value) ->
                    scope.title = value
                    scope.$scan()

        el = ttDOM """
            {{name}}
            <div al-test="name">
                {{title}}-{{title2}}
            </div>
        """

        scope = alight.Scope()
        scope.name = 'linux'

        alight.bind scope, el

        $test.equal ttGetText(el), 'linux linux-'
        
        scope.name = 'ubuntu'
        scope.$scan()
        $test.equal ttGetText(el), 'ubuntu ubuntu-'

        $test.close()


Test 'stop-binding-0'
    .run ($test, alight) ->
        $test.start 1

        alight.d.al.one =
            stopBinding: true

        el = ttDOM '<div>{{name}} <div al-one>{{name}}</div> </div>'

        alight.bootstrap el,
            name: 'linux'

        $test.equal ttGetText(el), 'linux {{name}}'

        $test.close()


Test 'stop-binding-1'
    .run ($test, alight) ->
        $test.start 1

        alight.d.al.one =
            link: (scope, el, key, env) ->
                if key is 'stop'
                    env.stopBinding = true

        el = ttDOM """
            <div>
                {{name}}
                <div al-one="stop">1{{name}}</div>
                <div al-one>2{{name}}</div>
            </div>
        """

        alight.bootstrap el,
            name: 'linux'

        $test.equal ttGetText(el), 'linux 1{{name}} 2linux'

        $test.close()


Test 'binding-order-0'
    .run ($test, alight) ->
        $test.start 1

        el = ttDOM """
            <div al-parent>
                <div al-repeat="it in list">
                    <i al-child></i>
                </div>
            </div>
        """

        order = []

        alight.d.al.parent = (scope) ->
            order.push 'p0'
            scope.$watch '$finishBinding', ->
                order.push 'p1'

        alight.d.al.child = (scope) ->
            order.push 'c0-' + scope.$index
            scope.$watch '$finishBinding', ->
                order.push 'c1-' + scope.$index

        scope = alight.bootstrap el,
            list: [{}, {}]

        order = order.join ' '
        $test.equal order, 'p0 c0-0 c0-1 p1 c1-0 c1-1'

        $test.close()


Test 'binding-order-1'
    .run ($test, alight) ->
        $test.start 2

        el = ttDOM """
            <div al-parent>
                <i al-child></i>
                <!-- directive: al-test -->
            </div>
        """

        order = []
        testCount = 0

        alight.d.al.parent =
            scope: true
            link: (scope) ->
                start: ->
                    order.push 'parent'

        alight.d.al.child = (scope) ->
            order.push 'child'

        alight.d.al.test =
            restrict: 'M'
            link: ->
                start: ->
                    testCount++

        alight.bootstrap el

        order = order.join ' '
        $test.equal order, 'parent child'
        $test.equal testCount, 1

        $test.close()
