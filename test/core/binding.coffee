
Test('binding 0', 'binding-0').run ($test, alight) ->
    $test.start 4

    alight.filters.double = ->
        (value) ->
            value + value

    dom = $ '<div attr="{{ num + 5 }}">Text {{ num | double }}</div>'
    scope =
        num: 15
    cd = alight.ChangeDetector scope

    alight.applyBindings cd, dom[0]

    $test.equal dom.text(), 'Text 30'
    $test.equal dom.attr('attr'), '20'

    scope.num = 50
    cd.scan ->
        $test.equal dom.text(), 'Text 100'
        $test.equal dom.attr('attr'), '55'
        $test.close()


Test('test-take-attr').run ($test, alight) ->

    alight.directives.ut =
        test0:
            priority: 500
            init: (scope, cd, el, name, env) ->
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

    cd = alight.ChangeDetector()

    alight.applyBindings cd, dom[0],
        skip_attr: ['ut-text']
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
            init: (scope, cd, el, name, env) ->
                $test.equal skippedAttr(env), 'ut-test-attr0,ut-two'
                $test.equal activeAttr(env), 'one,ut-test-attr1,ut-three'
                env.takeAttr 'ut-three'
                $test.equal skippedAttr(env), 'ut-test-attr0,ut-three,ut-two'
                $test.equal activeAttr(env), 'one,ut-test-attr1'

        testAttr1:
            priority: -50
            init: (scope, cd, el, name, env) ->
                $test.equal skippedAttr(env), 'one,ut-test-attr0,ut-test-attr1,ut-three,ut-two'
                $test.equal activeAttr(env), ''

    cd = alight.ChangeDetector()
    dom = document.createElement 'div'
    dom.innerHTML = '<div one="1" ut-test-attr1 ut-test-attr0 ut-two ut-three></div>'
    element = dom.children[0]

    alight.applyBindings cd, element,
        skip_attr: ['ut-two']
    $test.close()


Test('deferred process', 'deferred-process').run ($test, alight, timeout) ->
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
            link: (scope, cd, el, name) ->
                scope.name = 'linux'
                scope5 = scope
        test3:
            templateUrl: 'testDeferredProcess'
            link: (scope, cd, el, name) ->
                scope.name = 'linux'
                scope3 = scope

    runOne = (template) ->
        root =
            name: 'root'
        cd = alight.ChangeDetector root

        dom = document.createElement 'div'
        dom.innerHTML = template

        alight.applyBindings cd, dom

        response =
            root: root
            cd: cd
            html: ->
                dom.innerHTML.toLowerCase()
        response

    r0 = runOne '<span ut-test5="noop"></span>'
    r1 = runOne '<span ut-test3="noop"></span>'

    timeout.add 200, ->
        # 0
        $test.equal alight.directives.ut.test5.template, undefined
        $test.equal r0.root.name, 'root'
        $test.equal r0.cd.children[0].scope.name, 'linux'
        $test.equal scope5.name, 'linux'
        $test.equal r0.html(), '<span ut-test5="noop"><p>linux</p></span>'
        
        # 1
        $test.equal scope3, r1.root
        $test.equal r1.root.name, 'linux'
        $test.equal r1.cd.children.length, 0
        $test.equal r1.html(), '<span ut-test3="noop"><p>linux</p></span>'
        
        $test.close()


Test('html prefix-data').run ($test, alight) ->
    $test.start 3

    r = []
    alight.directives.al.test = (scope, cd, el, value) ->
        r.push value

    dom = $ '<div> <b al-test="one"></b> <b data-al-test="two"></b> </div>'
    alight.applyBindings alight.ChangeDetector(), dom[0]

    $test.equal r[0], 'one'
    $test.equal r[1], 'two'
    $test.equal r.length, 2

    $test.close()


Test 'root-scope-access-to-parent'
    .run ($test, alight) ->
        $test.start 2

        alight.ctrl.test =
            scope: true
            ChangeDetector: 'root'
            link: (scope, cd, el, key, env) ->
                env.parentChangeDetector.watch key, (value) ->
                    scope.title = value
                    cd.scan()

        el = ttDOM """
            {{name}}
            <div ctrl-test="name">
                {{title}}-{{title2}}
            </div>
        """

        cd = alight.ChangeDetector
            name: 'linux'

        alight.bind cd, el

        $test.equal ttGetText(el), 'linux linux-'
        
        cd.scope.name = 'ubuntu'
        cd.scan()
        $test.equal ttGetText(el), 'ubuntu ubuntu-'

        $test.close()


Test 'stop-binding-0'
    .run ($test, alight) ->
        $test.start 1

        alight.ctrl.one =
            stopBinding: true

        el = ttDOM '<div>{{name}} <div ctrl-one>{{name}}</div> </div>'

        alight.bootstrap
            $el: el
            name: 'linux'

        $test.equal ttGetText(el), 'linux {{name}}'

        $test.close()


Test 'stop-binding-1'
    .run ($test, alight) ->
        $test.start 1

        alight.ctrl.one =
            link: (scope, cd, el, key, env) ->
                if key is 'stop'
                    env.stopBinding = true

        el = ttDOM """
            <div>
                {{name}}
                <div ctrl-one="stop">1{{name}}</div>
                <div ctrl-one>2{{name}}</div>
            </div>
        """

        alight.bootstrap
            $el: el
            name: 'linux'

        $test.equal ttGetText(el), 'linux 1{{name}} 2linux'

        $test.close()


Test 'binding-order-0'
    .run ($test, alight) ->
        $test.start 1

        el = ttDOM """
            <div ctrl-parent>
                <div al-repeat="it in list">
                    <i ctrl-child></i>
                </div>
            </div>
        """

        order = []

        alight.ctrl.parent = (scope, cd) ->
            order.push 'p0'
            cd.watch '$finishBinding', ->
                order.push 'p1'

        alight.ctrl.child = (scope, cd) ->
            order.push 'c0-' + scope.$index
            cd.watch '$finishBinding', ->
                order.push 'c1-' + scope.$index

        cd = alight.bootstrap
            $el: el
            list: [{}, {}]

        order = order.join ' '
        $test.equal order, 'p0 c0-0 c0-1 p1 c1-0 c1-1'

        $test.close()
