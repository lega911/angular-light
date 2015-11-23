
Test('$watch').run ($test, alight) ->
    $test.start 1
    scope =
        one: 'one'
    cd = alight.ChangeDetector scope

    result = null
    w = cd.watch 'one + " " + two', (value) ->
        result = value

    scope.two = 'two'
    cd.scan ->
        if result is 'one two'
            w.stop()
            scope.two = '2'
            cd.scan ->
                $test.check result is 'one two'
                $test.close()
        else
            $test.error()
            $test.close()


Test('$watch #2').run ($test, alight) ->
    $test.start 2
    scope =
        name: 'linux'
    cd = alight.ChangeDetector scope

    w0 = cd.watch 'name', ->
    w1 = cd.watch 'name', ->

    $test.equal w0.value, 'linux'
    $test.equal w1.value, 'linux'
    $test.close()


Test('$watch #3', 'watch-3').run ($test, alight) ->
    $test.start 20
    scope =
        data:
            a: 'A'
            b: 'B'
    cd = alight.ChangeDetector scope

    valueA = null
    valueB = null
    countA = 0
    countB = 0
    watchA = cd.watch 'data.a', (value) ->
        valueA = value
        countA++
    watchB = cd.watch 'data.b', (value) ->
        valueB = value
        countB++

    cd.scan ->
        $test.equal countA, 0
        $test.equal valueA, null
        $test.equal countB, 0
        $test.equal valueB, null

        scope.data.a = '3'
        cd.scan ->
            $test.equal countA, 1
            $test.equal valueA, '3'
            $test.equal countB, 0
            $test.equal valueB, null

            scope.data.a = '3'
            scope.data.b = 'X'
            cd.scan ->
                $test.equal countA, 1
                $test.equal valueA, '3'
                $test.equal countB, 1
                $test.equal valueB, 'X'

                watchA.stop()
                scope.data.a = 'Y'
                scope.data.b = 'Z'
                cd.scan ->
                    $test.equal countA, 1
                    $test.equal valueA, '3'
                    $test.equal countB, 2
                    $test.equal valueB, 'Z'

                    watchB.stop()
                    scope.data.a = 'C'
                    scope.data.b = 'D'
                    cd.scan ->
                        $test.equal countA, 1
                        $test.equal valueA, '3'
                        $test.equal countB, 2
                        $test.equal valueB, 'Z'
                        $test.close()


Test('$watchArray').run ($test, alight) ->
    $test.start 12
    cd = alight.ChangeDetector()
    scope = cd.scope
    #scope.list = null

    watch = 0
    watchArray = 0

    cd.watch 'list', ->
        watch++
    cd.watch 'list', ->
        watchArray++
    , true

    cd.scan ->
        $test.equal watch, 0
        $test.equal watchArray, 0

        scope.list = [1, 2, 3]
        cd.scan ->
            $test.equal watch, 1
            $test.equal watchArray, 1

            scope.list = [1, 2]
            cd.scan ->
                $test.equal watch, 2  # watch should fire on objects, but filter generates new object every time, that create infinity loop
                $test.equal watchArray, 2

                scope.list.push(3)
                cd.scan ->
                    $test.equal watch, 2
                    $test.equal watchArray, 3, 'list.push 3'

                    cd.scan ->
                        $test.equal watch, 2
                        $test.equal watchArray, 3, 'none'

                        scope.list = 7
                        cd.scan ->
                            $test.equal watch, 3
                            $test.equal watchArray, 4, 'list = 7'
                            $test.close()


Test('$watchArray#2').run ($test, alight) ->
    $test.start 4
    scope = {}
    cd = alight.ChangeDetector scope
    #scope.list = null

    watch = 0
    watchArray = 0

    cd.watch 'list', ->
        watch++
    cd.watch 'list', ->
        watchArray++
    , true

    cd.scan ->
        $test.check watch is 0 and watchArray is 0
        scope.list = []
        cd.scan ->
            $test.check watch is 1 and watchArray is 1

            scope.list = [1, 2, 3]
            cd.scan ->
                $test.check watch is 2 and watchArray is 2

                scope.list.push(4)
                cd.scan ->
                    $test.check watch is 2 and watchArray is 3
                    $test.close()


Test('$watch $any').run ($test, alight) ->
    $test.start 15
    scope =
        a: 1
        b: 1
    cd = alight.ChangeDetector scope

    countAny = 0
    countAny2 = 0
    countA = 0

    wa = cd.watch '$any', ->
        countAny++

    cd.watch '$any', ->
        countAny2++

    cd.watch 'a', ->
        countA++

    $test.equal countA, 0
    $test.equal countAny, 0
    $test.equal countAny2, 0

    scope.b++
    cd.scan ->
        $test.equal countA, 0
        $test.equal countAny, 0
        $test.equal countAny2, 0

        scope.a++
        cd.scan ->
            $test.equal countA, 1
            $test.equal countAny, 1
            $test.equal countAny2, 1

            wa.stop()
            scope.a++
            cd.scan ->
                $test.equal countA, 2
                $test.equal countAny, 1
                $test.equal countAny2, 2

                cd.destroy()
                scope.a++
                cd.scan ->
                    $test.equal countA, 2
                    $test.equal countAny, 1
                    $test.equal countAny2, 2

                    $test.close()


Test('$watch $finishScan', 'watch-finish-scan').run ($test, alight) ->
    $test.start 20
    cd = alight.ChangeDetector()

    count0 = 0
    count1 = 0
    count2 = 0
    count3 = 0

    wa = cd.watch '$finishScan', ->
        count0++
    cd.watch '$finishScan', ->
        count1++
    child = cd.new()
    wa2 = child.watch '$finishScan', ->
        count2++
    child.watch '$finishScan', ->
        count3++

    $test.equal count0, 0
    $test.equal count1, 0
    $test.equal count2, 0
    $test.equal count3, 0
    cd.scan()
    alight.nextTick ->
        $test.equal count0, 1
        $test.equal count1, 1
        $test.equal count2, 1
        $test.equal count3, 1

        wa.stop()
        wa2.stop()
        cd.scan()
        alight.nextTick ->
            $test.equal count0, 1
            $test.equal count1, 2
            $test.equal count2, 1
            $test.equal count3, 2

            child.destroy()
            cd.scan()
            alight.nextTick ->
                $test.equal count0, 1
                $test.equal count1, 3
                $test.equal count2, 1
                $test.equal count3, 2

                cd.destroy()
                cd.scan()
                alight.nextTick ->
                    $test.equal count0, 1
                    $test.equal count1, 3
                    $test.equal count2, 1
                    $test.equal count3, 2

                    $test.close()


Test('test dynamic read-only watch').run ($test, alight) ->
    $test.start 6
    scope =
        one: 'one'
    cd = alight.ChangeDetector scope

    noop = ->
    result = null

    count = 0
    cd.watch ->
        count++
        ''
    , noop,
        readOnly: true

    cd.watch 'one', ->
        result

    $test.equal count, 1 # init
    cd.scan ->
        $test.equal count, 2

        scope.one = 'two'
        cd.scan ->
            $test.equal count, 4 # 2-loop

            cd.scan ->
                $test.equal count, 5

                result = '$scanNoChanges'
                scope.one = 'three'
                cd.scan ->
                    $test.equal count, 6
    
                    cd.scan ->
                        $test.equal count, 7
                        $test.close()


