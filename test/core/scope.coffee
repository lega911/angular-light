
Test('scope-root-0', 'scope-root-0').run ($test, alight) ->
    $test.start 24

    c0 = 0
    c1 = 0
    c2 = 0
    c3 = 0

    scope =
        name: 'linux'
    root = alight.ChangeDetector scope

    child = alight.ChangeDetector
        $parent: scope

    # attach parent
    root.watch '$destroy', ->
        child.destroy()
    child.$parent = root

    child.$parent.watch 'name', ->
        c0 += 1
    child.watch '$parent.name', ->
        c1 += 1
    child.watch 'ex', ->
        c2 += 1
    child.watch '$destroy', ->
        c3 += 1

    root.scan()
    child.scan()

    $test.equal c0, 1
    $test.equal c1, 1
    $test.equal c2, 1
    $test.equal c3, 0

    scope.name = 'ubuntu'
    root.scan()
    $test.equal c0, 2
    $test.equal c1, 1
    $test.equal c2, 1
    $test.equal c3, 0

    child.scan()
    $test.equal c0, 2
    $test.equal c1, 2
    $test.equal c2, 1
    $test.equal c3, 0

    child.scope.ex = 5
    root.scan()
    child.scan()
    $test.equal c0, 2
    $test.equal c1, 2
    $test.equal c2, 2, '15'
    $test.equal c3, 0

    root.destroy()
    $test.equal c0, 2
    $test.equal c1, 2
    $test.equal c2, 2
    $test.equal c3, 1

    scope.name = 'macos'
    root.scan()
    child.scan()
    $test.equal c0, 2
    $test.equal c1, 2
    $test.equal c2, 2
    $test.equal c3, 1

    $test.close()


Test('root-destroy-0', 'root-destroy-0').run ($test, alight) ->
    $test.start 6

    cd = alight.ChangeDetector()

    cd1 = cd.new()
    cd2 = cd1.new()

    a = 0
    b = 0
    c = 0

    cd.watch '$destroy', ->
        a++

    cd1.watch '$destroy', ->
        b++

    cd2.watch '$destroy', ->
        c++

    cd.scan()

    $test.equal a, 0
    $test.equal b, 0
    $test.equal c, 0

    cd.root.destroy()

    $test.equal a, 1
    $test.equal b, 1
    $test.equal c, 1

    $test.close()


Test('root-destroy-1', 'root-destroy-1').run ($test, alight) ->
    $test.start 18

    cd = alight.ChangeDetector()

    cd1 = cd.new()
    cd2 = cd1.new()

    a = 0
    a1 = 0
    b = 0
    b1 = 0
    c = 0
    c1 = 0

    cd.watch '$destroy', ->
        a++
    cd.watch '$finishScan', ->
        a1++

    cd1.watch '$destroy', ->
        b++
    cd1.watch '$finishScan', ->
        b1++

    cd2.watch '$destroy', ->
        c++
    cd2.watch '$finishScan', ->
        c1++

    cd1.scan()

    $test.equal a, 0
    $test.equal b, 0
    $test.equal c, 0
    $test.equal a1, 1
    $test.equal b1, 1
    $test.equal c1, 1

    cd1.destroy()
    cd1.scan()

    $test.equal a, 0
    $test.equal b, 1
    $test.equal c, 1
    $test.equal a1, 2
    $test.equal b1, 1
    $test.equal c1, 1

    cd.destroy()
    cd.scan()

    $test.equal a, 1
    $test.equal b, 1
    $test.equal c, 1
    $test.equal a1, 2
    $test.equal b1, 1
    $test.equal c1, 1

    $test.close()


Test 'al-repeat-child-cd-0'
    .run ($test, alight) ->
        $test.start 1

        alight.d.al.test = (scope, el, val, env) ->
            it = env.getValue 'it'
            it.name += '_rc'

        el = ttDOM '''
            r{{it?.name}}#
            <div al-repeat="it in list">
                {{$index}}={{it.name}}
                <span al-test></span>
            </div>
        '''

        scope = alight el,
            list: [
                {name: 'linux'}
                {name: 'macos'}
                {name: 'windows'}
            ]

        $test.equal ttGetText(el), 'r# 0=linux_rc 1=macos_rc 2=windows_rc'

        $test.close()


Test 'isolated-scope-0'
    .run ($test, alight, timeout) ->
        if $test.basis
            return 'skip'
        alight.option.injectScope = true
        $test.start 2

        el = ttDOM """
            root={{top}}-{{child}}-{{one}}
            <div al-test>
                child={{top}}-{{child}}-{{one}}
            </div>
        """

        scope = alight.Scope()
        scope.top = 'unix'

        alight.d.al.test =
            scope: true
            link: (scope) ->
                scope.child = 'linux'
                scope.$setValue 'one', 'two'

                timeout.add 10, ->
                    scope.$setValue 'one', 'three'
                    scope.$scan()

        alight.bind scope, el

        $test.equal ttGetText(el), 'root=unix-- child=-linux-two'
        timeout.add 20, ->

            $test.equal ttGetText(el), 'root=unix-- child=-linux-three'
            $test.close()


Test('locals-0').run ($test, alight) ->
    $test.start 20

    root = alight.ChangeDetector()
    root.scope.x = 1

    cd0 = root.new null,
        locals: true
    cd0.locals.x = 2

    cd1 = cd0.new()

    cd2 = cd1.new null,
        locals: true

    cd3 = cd2.new()

    $test.equal root.getValue('x'), 1
    $test.equal cd0.getValue('x'), 2
    $test.equal cd1.getValue('x'), 2
    $test.equal cd2.getValue('x'), 2
    $test.equal cd3.getValue('x'), 2

    cd1.locals.x = 3
    $test.equal root.getValue('x'), 1
    $test.equal cd0.getValue('x'), 3
    $test.equal cd1.getValue('x'), 3
    $test.equal cd2.getValue('x'), 3
    $test.equal cd3.getValue('x'), 3

    cd2.locals.x = 4
    $test.equal root.getValue('x'), 1
    $test.equal cd0.getValue('x'), 3
    $test.equal cd1.getValue('x'), 3
    $test.equal cd2.getValue('x'), 4
    $test.equal cd3.getValue('x'), 4

    cd3.locals.x = 5
    $test.equal root.getValue('x'), 1
    $test.equal cd0.getValue('x'), 3
    $test.equal cd1.getValue('x'), 3
    $test.equal cd2.getValue('x'), 5
    $test.equal cd3.getValue('x'), 5

    $test.close()
