
setupAlight = (alight) ->
    alight.controllers.testRepeat = (scope) ->
        scope.r = scope.it.text + scope.it.text

do ->
    ###
        al-repeat="item in list" al-controller="itemController"
        "item in list"
        "item in list | filter"
        "item in list | filter track by track_expression"
        "item in list track by $index"
        "item in list track by $id(item)"
        "item in list track by item.id"

        * build list
        * push an item
        * insert 0
        * insert 2
        * remove 0
        * remove last
        * remove middle
        * change an item
    ###

    run = (name, html, results) ->
        Test('al-repeat ' + name).run ($test, alight) ->
            $test.start 8
            setupAlight alight

            dom = $ "<span>#{html}</span>"

            scope = alight.Scope()
            scope.numerator = do ->
                n = 1
                ->
                    n++
            scope.list = [
                { text: 'a' },
                { text: 'b' },
                { text: 'c' },
                { text: 'd' }
            ]

            alight.applyBindings scope, dom[0]

            result = ->
                r = for e in dom.find('div')
                    $(e).text()
                r.join ', '
            $test.check result() is results[0], result()

            scope.list.push { text: 'e' }
            scope.$scan ->
                $test.check result() is results[1], result()

                scope.list.splice 0, 0, { text: 'f' }
                scope.$scan ->
                    $test.equal result(), results[2], result()

                    scope.list.splice 2, 0, { text: 'g' }, { text: 'h' }
                    scope.$scan ->
                        $test.check result() is results[3], result()

                        scope.list.splice 0, 1
                        scope.$scan ->
                            $test.check result() is results[4], result()

                            scope.list.splice 6, 1
                            scope.$scan ->
                                $test.check result() is results[5], result()

                                scope.list.splice 2, 2
                                scope.$scan ->
                                    $test.check result() is results[6], result()

                                    scope.list[1] = { text:'i' }
                                    scope.$scan ->
                                        $test.check result() is results[7], result()
                                        $test.close()

    run 'default', '<div al-repeat="it in list">{{it.text}}:{{=numerator()}}</div>',
        0: 'a:1, b:2, c:3, d:4'
        1: 'a:1, b:2, c:3, d:4, e:5'
        2: 'f:6, a:1, b:2, c:3, d:4, e:5'
        3: 'f:6, a:1, g:7, h:8, b:2, c:3, d:4, e:5'
        4: 'a:1, g:7, h:8, b:2, c:3, d:4, e:5'
        5: 'a:1, g:7, h:8, b:2, c:3, d:4'
        6: 'a:1, g:7, c:3, d:4'
        7: 'a:1, i:9, c:3, d:4'

    run 'by $id(it)', '<div al-repeat="it in list track by $id(it)">{{it.text}}:{{=numerator()}}</div>',
        0: 'a:1, b:2, c:3, d:4'
        1: 'a:1, b:2, c:3, d:4, e:5'
        2: 'f:6, a:1, b:2, c:3, d:4, e:5'
        3: 'f:6, a:1, g:7, h:8, b:2, c:3, d:4, e:5'
        4: 'a:1, g:7, h:8, b:2, c:3, d:4, e:5'
        5: 'a:1, g:7, h:8, b:2, c:3, d:4'
        6: 'a:1, g:7, c:3, d:4'
        7: 'a:1, i:9, c:3, d:4'

    run 'by it.text', '<div al-repeat="it in list track by it.text">{{it.text}}:{{=numerator()}}</div>',
        0: 'a:1, b:2, c:3, d:4'
        1: 'a:1, b:2, c:3, d:4, e:5'
        2: 'f:6, a:1, b:2, c:3, d:4, e:5'
        3: 'f:6, a:1, g:7, h:8, b:2, c:3, d:4, e:5'
        4: 'a:1, g:7, h:8, b:2, c:3, d:4, e:5'
        5: 'a:1, g:7, h:8, b:2, c:3, d:4'
        6: 'a:1, g:7, c:3, d:4'
        7: 'a:1, i:9, c:3, d:4'

    run 'by $index, objects', '<div al-repeat="it in list track by $index">{{it.text}}:{{=numerator()}}</div>',
        0: 'a:1, b:2, c:3, d:4'
        1: 'a:1, b:2, c:3, d:4, e:5'
        2: 'f:1, a:2, b:3, c:4, d:5, e:6'
        3: 'f:1, a:2, g:3, h:4, b:5, c:6, d:7, e:8'
        4: 'a:1, g:2, h:3, b:4, c:5, d:6, e:7'
        5: 'a:1, g:2, h:3, b:4, c:5, d:6'
        6: 'a:1, g:2, c:3, d:4'
        7: 'a:1, i:2, c:3, d:4'

    run 'filter + controller', '<div al-repeat="it in list | slice:0,3" al-controller="testRepeat">{{r}}:{{=numerator()}}</div>',
        0: 'aa:1, bb:2, cc:3'
        1: 'aa:1, bb:2, cc:3'
        2: 'ff:4, aa:1, bb:2'
        3: 'ff:4, aa:1, gg:5'
        4: 'aa:1, gg:5, hh:6'
        5: 'aa:1, gg:5, hh:6'
        6: 'aa:1, gg:5, cc:7'
        7: 'aa:1, ii:8, cc:7'

    run 'bo-repeat', '<div bo-repeat="it in list" al-controller="testRepeat">{{r}}:{{=numerator()}}</div>',
        0: 'aa:1, bb:2, cc:3, dd:4'
        1: 'aa:1, bb:2, cc:3, dd:4'
        2: 'aa:1, bb:2, cc:3, dd:4'
        3: 'aa:1, bb:2, cc:3, dd:4'
        4: 'aa:1, bb:2, cc:3, dd:4'
        5: 'aa:1, bb:2, cc:3, dd:4'
        6: 'aa:1, bb:2, cc:3, dd:4'
        7: 'aa:1, bb:2, cc:3, dd:4'

    Test('by $index, primitives').run ($test, alight) ->
        $test.start 8
        setupAlight alight

        scope = alight.Scope()
        scope.list = ['a', 'b', 'c', 'd']
        scope.numerator = do ->
            index = 0
            ->
                index++

        dom = document.createElement 'div'
        dom.innerHTML = '<div class="item" al-repeat="it in list track by $index">{{it}}:{{=numerator()}}</div>'

        alight.applyBindings scope, dom

        result = ->
            r = for e in alight.f$.find dom, '.item'
                alight.f$.text e
            r.join ', '

        ops = [
            (next) ->
                $test.equal result(), 'a:0, b:1, c:2, d:3'
                next()
            (next) ->
                scope.list.push 'e'
                scope.$scan
                    late: true
                    callback: ->
                        $test.equal result(), 'a:0, b:1, c:2, d:3, e:4'
                        next()
            (next) ->
                scope.list.splice 0, 0, 'f'
                scope.$scan
                    late: true
                    callback: ->
                        $test.equal result(), 'f:0, a:1, b:2, c:3, d:4, e:5'
                        next()
            (next) ->
                scope.list.splice 2, 0, 'g'
                scope.$scan
                    late: true
                    callback: ->
                        $test.equal result(), 'f:0, a:1, g:2, b:3, c:4, d:5, e:6'
                        next()
            (next) ->
                scope.list = ['f', 'a', 'g', 'b', 'h', 'c', 'd', 'e']
                scope.$scan
                    late: true
                    callback: ->
                        $test.equal result(), 'f:0, a:1, g:2, b:3, h:4, c:5, d:6, e:7'
                        next()
            (next) ->
                scope.list = ['f', 'b', 'h', 'c', 'd']
                scope.$scan
                    late: false
                    callback: ->
                        $test.equal result(), 'f:0, b:1, h:2, c:3, d:4'
                        next()
            (next) ->
                scope.list = ['f', 'b', 'h', 'i', 'c', 'd', 'j']
                scope.$scan
                    late: true
                    callback: ->
                        $test.equal result(), 'f:0, b:1, h:2, i:3, c:4, d:8, j:9'
                        next()
            (next) ->
                scope.list = ['b', 'c', 'd', 'f', 'h', 'i', 'j']
                scope.$scan ->
                    scope.$scan ->
                        $test.equal result(), 'b:0, c:1, d:2, f:3, h:4, i:8, j:9'
                        next()
                        $test.close()
        ]

        i = 0
        next = ->
            op = ops[i++]
            if op
                op next
        next()

        null


Test('al-repeat skippedAttr').run ($test, alight) ->
    $test.start 10
    setupAlight alight

    activeAttr = (env) ->
        r = for i in env.attributes
            if i.skip
                continue
            i.attrName
        r.sort().join ','

    skippedAttr = (env) ->
        r = env.skippedAttr()
        r.sort().join ','

    countHi = 0
    countLo = 0

    alight.directives.ut =
        testAttr2:
            priority: 5000
            init: (el, name, scope, env) ->
                countHi++
                $test.equal skippedAttr(env), 'ut-test-attr2,ut-two'
                $test.equal activeAttr(env), 'al-repeat,one,ut-test-attr3,ut-three'
        testAttr3:
            priority: 50
            init: (el, name, scope, env) ->
                countLo++
                $test.equal skippedAttr(env), 'al-repeat,ut-test-attr2,ut-test-attr3,ut-two'
                $test.equal activeAttr(env), 'one,ut-three'
                env.takeAttr 'ut-three'

    scope = alight.Scope()
    dom = document.createElement 'div'
    dom.innerHTML = '<div al-repeat="it in [1,2,3] track by $index" one="1" ut-test-attr2 ut-test-attr3 ut-two ut-three></div>'
    element = dom.children[0]

    alight.applyBindings scope, element,
        skip_attr: ['ut-two']

    $test.equal countHi, 1, 'countHi'
    $test.equal countLo, 3, 'countLo'
    $test.close()


Test('al-repeat one-time-bindings').run ($test, alight) ->
    $test.start 6
    setupAlight alight

    scope = alight.Scope()
    dom = document.createElement 'div'
    dom.innerHTML = '<div class="item" al-repeat="it in ::list"></div>'
    element = dom.children[0]

    alight.applyBindings scope, element

    watchCount = ->
        r = for i of scope.$system.watches
            i
        r.length

    rowCount = ->
        r = for e in alight.f$.find dom, '.item'
            e
        r.length

    $test.equal watchCount(), 1
    $test.equal rowCount(), 0

    scope.list = [{}, {}, {}]
    scope.$scan ->
        $test.equal watchCount(), 0
        $test.equal rowCount(), 3

        scope.list = [{}, {}, {}, {}, {}]
        scope.$scan ->
            $test.equal watchCount(), 0
            $test.equal rowCount(), 3
            $test.close()
