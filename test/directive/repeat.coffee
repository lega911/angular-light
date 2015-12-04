
setupAlight = (alight) ->
    alight.d.al.testRepeat = (scope) ->
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

    run = (name, html, results, makeResult) ->
        Test('al-repeat-' + name, 'al-repeat-'+name).run ($test, alight, timeout) ->
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

            alight.bind scope, dom[0]

            result = ->
                if makeResult
                    return makeResult dom
                else
                    r = for e in dom.find('div')
                        $(e).text()
                    r.join ', '

            $test.equal result(), results[0]

            scope.list.push { text: 'e' }
            scope.$scan()
            timeout.add 1, ->
                $test.check result() is results[1], result()

                scope.list.splice 0, 0, { text: 'f' }
                scope.$scan()
                timeout.add 1, ->
                    $test.equal result(), results[2], result()

                    scope.list.splice 2, 0, { text: 'g' }, { text: 'h' }
                    scope.$scan()
                    timeout.add 1, ->
                        $test.check result() is results[3], result()

                        scope.list.splice 0, 1
                        scope.$scan()
                        timeout.add 1, ->
                            $test.check result() is results[4], result()

                            scope.list.splice 6, 1
                            scope.$scan()
                            timeout.add 1, ->
                                $test.check result() is results[5], result()

                                scope.list.splice 2, 2
                                scope.$scan()
                                timeout.add 1, ->
                                    $test.check result() is results[6], result()

                                    scope.list[1] = { text:'i' }
                                    scope.$scan()
                                    timeout.add 1, ->
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

    run 'filter-controller', '<div al-repeat="it in list | slice:0,3" al-test-repeat>{{r}}:{{=numerator()}}</div>',
        0: 'aa:1, bb:2, cc:3'
        1: 'aa:1, bb:2, cc:3'
        2: 'ff:4, aa:1, bb:2'
        3: 'ff:4, aa:1, gg:5'
        4: 'aa:1, gg:5, hh:6'
        5: 'aa:1, gg:5, hh:6'
        6: 'aa:1, gg:5, cc:7'
        7: 'aa:1, ii:8, cc:7'

    run 'bo-repeat', '<div bo-repeat="it in list" al-test-repeat>{{r}}:{{=numerator()}}</div>',
        0: 'aa:1, bb:2, cc:3, dd:4'
        1: 'aa:1, bb:2, cc:3, dd:4'
        2: 'aa:1, bb:2, cc:3, dd:4'
        3: 'aa:1, bb:2, cc:3, dd:4'
        4: 'aa:1, bb:2, cc:3, dd:4'
        5: 'aa:1, bb:2, cc:3, dd:4'
        6: 'aa:1, bb:2, cc:3, dd:4'
        7: 'aa:1, bb:2, cc:3, dd:4'

    run 'restrict-m', '<div> <!-- directive: al-repeat item in list--><span>{{item.text}}</span>:{{=numerator()}}:<span>{{item.text}}</span> <!--  /directive:  al-repeat --> </div>',
        0: 'a:1:a b:2:b c:3:c d:4:d'
        1: 'a:1:a b:2:b c:3:c d:4:d e:5:e'
        2: 'f:6:f a:1:a b:2:b c:3:c d:4:d e:5:e'
        3: 'f:6:f a:1:a g:7:g h:8:h b:2:b c:3:c d:4:d e:5:e'
        4: 'a:1:a g:7:g h:8:h b:2:b c:3:c d:4:d e:5:e'
        5: 'a:1:a g:7:g h:8:h b:2:b c:3:c d:4:d'
        6: 'a:1:a g:7:g c:3:c d:4:d'
        7: 'a:1:a i:9:i c:3:c d:4:d'
    , (dom) ->
        $(dom).text().trim()

    Test('by $index, primitives', 'by-index-primitives').run ($test, alight) ->
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

        alight.bin scope, dom

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
                cd.scan
                    late: true
                    callback: ->
                        $test.equal result(), 'a:0, b:1, c:2, d:3, e:4'
                        next()
            (next) ->
                scope.list.splice 0, 0, 'f'
                cd.scan
                    late: true
                    callback: ->
                        $test.equal result(), 'f:0, a:1, b:2, c:3, d:4, e:5'
                        next()
            (next) ->
                scope.list.splice 2, 0, 'g'
                cd.scan
                    late: true
                    callback: ->
                        $test.equal result(), 'f:0, a:1, g:2, b:3, c:4, d:5, e:6'
                        next()
            (next) ->
                scope.list = ['f', 'a', 'g', 'b', 'h', 'c', 'd', 'e']
                cd.scan
                    late: true
                    callback: ->
                        $test.equal result(), 'f:0, a:1, g:2, b:3, h:4, c:5, d:6, e:7'
                        next()
            (next) ->
                scope.list = ['f', 'b', 'h', 'c', 'd']
                cd.scan
                    late: false
                    callback: ->
                        $test.equal result(), 'f:0, b:1, h:2, c:3, d:4'
                        next()
            (next) ->
                scope.list = ['f', 'b', 'h', 'i', 'c', 'd', 'j']
                cd.scan
                    late: true
                    callback: ->
                        $test.equal result(), 'f:0, b:1, h:2, i:3, c:4, d:8, j:9'
                        next()
            (next) ->
                scope.list = ['b', 'c', 'd', 'f', 'h', 'i', 'j']
                cd.scan ->
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


Test('al-repeat-skipped-attr').run ($test, alight) ->
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
            init: (scope, el, name, env) ->
                countHi++
                $test.equal skippedAttr(env), 'ut-test-attr2,ut-two'
                $test.equal activeAttr(env), 'al-repeat,one,ut-test-attr3,ut-three'
        testAttr3:
            priority: 50
            init: (scope, el, name, env) ->
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


Test('al-repeat one-time-bindings', 'al-repeat-one-time-bindings').run ($test, alight) ->
    $test.start 6
    setupAlight alight

    cd = alight.ChangeDetector()
    scope = cd.scope
    dom = document.createElement 'div'
    dom.innerHTML = '<div class="item" al-repeat="it in ::list"></div>'
    element = dom.children[0]

    alight.applyBindings cd, element

    watchCount = ->
        return cd.scan().total

    rowCount = ->
        r = for e in alight.f$.find dom, '.item'
            e
        r.length

    $test.equal watchCount(), 1
    $test.equal rowCount(), 0

    scope.list = [{}, {}, {}]
    cd.scan ->
        $test.equal watchCount(), 0
        $test.equal rowCount(), 3

        scope.list = [{}, {}, {}, {}, {}]
        cd.scan ->
            $test.equal watchCount(), 0
            $test.equal rowCount(), 3
            $test.close()


Test('repeat-store-to-0', 'repeat-store-to-0').run ($test, alight) ->
    $test.start 6

    setter = null
    alight.filters.myfilter = (_a, _b, env) ->
        setter = env.setValue
        onChange: (value) ->
            env.setValue makeResult

    scope = {}
    cd = alight.ChangeDetector scope
    dom = document.createElement 'div'
    dom.innerHTML = '<div class="item" al-repeat="it in list | myfilter store to filteredList"></div>'

    scope.filteredList = []
    scope.list = list = makeResult = [
        {t: 'a'},
        {t: 'b'},
        {t: 'c'},
        {t: 'd'},
        {t: 'e'},
        {t: 'f'}
    ]

    flen = 0
    fcount = 0
    cd.watch 'filteredList.length', (value) ->
        flen = value
        fcount++

    alight.applyBindings cd, dom

    $test.equal fcount, 2
    $test.equal flen, 6

    cd.scan ->
        $test.equal fcount, 2
        $test.equal flen, 6

        makeResult = [list[1], list[2], list[3]]
        setter makeResult
        cd.scan ->
            $test.equal fcount, 3
            $test.equal flen, 3

            $test.close()


Test('al-repeat track by 4', 'al-repeat-track-by-4').run ($test, alight) ->
    $test.start 3

    element = document.createElement 'div'
    element.innerHTML = '<div class="item" al-repeat="it in list track by $index">{{it}}</div>'

    scope =
        list: [0, 1, 2, 3, 4]
    cd = alight.ChangeDetector scope

    alight.applyBindings cd, element

    getText = ->
        element.innerText.replace(/\s/g, '')

    $test.equal getText(), '01234'
    scope.list = []
    cd.scan ->
        $test.equal getText(), ''
        scope.list = [0, 1, 2, 3, 4]
        cd.scan ->
            $test.equal getText(), '01234'
            $test.close()


Test('al-repeat track by 5', 'al-repeat-track-by-5').run ($test, alight) ->
    $test.start 2

    index = 1
    alight.d.al.index = (scope, cd, el, _) ->
        el.innerHTML = '' + index
        index++

    element = document.createElement 'div'
    element.innerHTML = '<div class="item" al-repeat="it in list track by it.k"><i al-index></i>{{it.name}}</div>'

    scope =
        list: [{k: 0, name: 'a'}, {k: 1, name: 'b'}, {k: 2, name: 'c'}]

    cd = alight.ChangeDetector scope
    alight.applyBindings cd, element

    getText = ->
        element.innerText.replace(/\s/g, '')

    $test.equal getText(), '1a2b3c'
    scope.list = [{k: 0, name: 'x'}, {k: 1, name: 'y'}, {k: 2, name: 'z'}]
    cd.scan ->
        $test.equal getText(), '1x2y3z'
        $test.close()


Test('al-repeat-transparent-assigment-0', 'al-repeat-transparent-assigment-0').run ($test, alight) ->
    $test.start 8

    childS = null
    alight.d.al.fire = (scope, cd) ->
        if scope.child isnt '14'
            return
        if scope.box.name isnt 'ubuntu'
            return
        childS = cd
        null

    el = ttDOM """
        <p al-repeat="box in list" al-init="firstLine=box.name">
            box={{box.name}}
            <i al-repeat="child in box.children" al-init="fromChild=child">{{child}} <b al-fire></b></i>
        </p>
    """

    scope =
        list: []
    scope.list.push
        name: 'linux'
        children: ['x86', 'x64']

    cd = alight.ChangeDetector scope
    alight.bind cd, el

    $test.equal ttGetText(el), 'box=linux x86 x64'
    $test.equal scope.firstLine, 'linux'
    $test.equal scope.fromChild, 'x64'

    scope.list.push
        name: 'ubuntu'
        children: ['14', '15']
    cd.scan()

    $test.equal ttGetText(el), 'box=linux x86 x64 box=ubuntu 14 15'
    $test.equal scope.firstLine, 'ubuntu'
    $test.equal scope.fromChild, '15'

    childS.scope.child = 'X'
    childS.scope.box.name = 'debian'
    childS.scan()
    $test.equal ttGetText(el), 'box=linux x86 x64 box=debian X 15'
    $test.equal childS.scope.$root, cd.scope

    $test.close()
