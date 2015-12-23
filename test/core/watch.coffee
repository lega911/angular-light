
Test('watch-0', 'watch-0').run ($test, alight) ->
    $test.start 2
    scope =
        one: 'one'
    cd = alight.ChangeDetector scope

    result = null
    w = cd.watch 'one + " " + two', (value) ->
        result = value

    scope.two = 'two'
    cd.scan ->
        $test.equal result, 'one two'
        w.stop()

        scope.two = '2'
        cd.scan ->
            $test.equal result, 'one two'
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
        $test.equal countA, 1
        $test.equal valueA, 'A'
        $test.equal countB, 1
        $test.equal valueB, 'B'

        scope.data.a = '3'
        cd.scan ->
            $test.equal countA, 2
            $test.equal valueA, '3'
            $test.equal countB, 1
            $test.equal valueB, 'B'

            scope.data.a = '3'
            scope.data.b = 'X'
            cd.scan ->
                $test.equal countA, 2, 'step 3'
                $test.equal valueA, '3'
                $test.equal countB, 2
                $test.equal valueB, 'X'

                watchA.stop()
                scope.data.a = 'Y'
                scope.data.b = 'Z'
                cd.scan ->
                    $test.equal countA, 2, 'step 4'
                    $test.equal valueA, '3'
                    $test.equal countB, 3
                    $test.equal valueB, 'Z'

                    watchB.stop()
                    scope.data.a = 'C'
                    scope.data.b = 'D'
                    cd.scan ->
                        $test.equal countA, 2
                        $test.equal valueA, '3'
                        $test.equal countB, 3
                        $test.equal valueB, 'Z'
                        $test.close()


Test('watch-4', 'watch-4').run ($test, alight) ->
    $test.start 2

    result0 = result1 = null

    cd = alight.ChangeDetector
        name: 'linux'

    cd.watch 'name', (value) ->
        result0 = value

    cd.scope.name = 'unix'
    cd.watch 'name', (value) ->
        result1 = value

    cd.scan()

    $test.equal result0, 'unix'
    $test.equal result1, 'unix'
    $test.close()


Test('watch-array', 'watch-array').run ($test, alight) ->
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
        $test.equal watch, 1
        $test.equal watchArray, 0

        scope.list = [1, 2, 3]
        cd.scan ->
            $test.equal watch, 2
            $test.equal watchArray, 1

            scope.list = [1, 2]
            cd.scan ->
                $test.equal watch, 3  # watch should fire on objects, but filter generates new object every time, that create infinity loop
                $test.equal watchArray, 2

                scope.list.push(3)
                cd.scan ->
                    $test.equal watch, 3
                    $test.equal watchArray, 3, 'list.push 3'

                    cd.scan ->
                        $test.equal watch, 3
                        $test.equal watchArray, 3, 'none'

                        scope.list = 7
                        cd.scan ->
                            $test.equal watch, 4
                            $test.equal watchArray, 4, 'list = 7'
                            $test.close()


Test('watch-array-2', 'watch-array-2').run ($test, alight) ->
    $test.start 8
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
        $test.equal watch, 1
        $test.equal watchArray, 0
        scope.list = []
        cd.scan ->
            $test.equal watch, 2
            $test.equal watchArray, 1

            scope.list = [1, 2, 3]
            cd.scan ->
                $test.equal watch, 3
                $test.equal watchArray, 2

                scope.list.push(4)
                cd.scan ->
                    $test.equal watch, 3
                    $test.equal watchArray, 3
                    $test.close()


Test('watch-frozen-array-0', 'watch-frozen-array-0').run ($test, alight) ->
    $test.start 12
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

    freeze = Object.freeze or ->

    cd.scan ->
        $test.equal watch, 1
        $test.equal watchArray, 0
        scope.list = []
        freeze scope.list
        cd.scan ->
            $test.equal watch, 2
            $test.equal watchArray, 1

            scope.list = [1, 2, 3]
            freeze scope.list
            cd.scan ->
                $test.equal watch, 3
                $test.equal watchArray, 2

                scope.list = scope.list.slice()
                scope.list.push(4)
                freeze scope.list
                cd.scan ->
                    $test.equal watch, 4
                    $test.equal watchArray, 3

                    scope.list = [1, 2, 3]
                    cd.scan ->
                        $test.equal watch, 5
                        $test.equal watchArray, 4

                        scope.list.push(4)
                        cd.scan ->
                            $test.equal watch, 5
                            $test.equal watchArray, 5
                            $test.close()


Test('watch-any').run ($test, alight) ->
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
        $test.equal countA, 1
        $test.equal countAny, 1
        $test.equal countAny2, 1

        scope.a++
        cd.scan ->
            $test.equal countA, 2
            $test.equal countAny, 2
            $test.equal countAny2, 2

            wa.stop()
            scope.a++
            cd.scan ->
                $test.equal countA, 3
                $test.equal countAny, 2
                $test.equal countAny2, 3

                cd.destroy()
                scope.a++
                cd.scan ->
                    $test.equal countA, 3
                    $test.equal countAny, 2
                    $test.equal countAny2, 3

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


Test('dynamic-read-only-watch', 'dynamic-read-only-watch').run ($test, alight) ->
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

    $test.equal count, 0 # init
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


Test('scan-skip-watch', 'scan-skip-watch').run ($test, alight) ->
    $test.start 5

    cd = alight.ChangeDetector
        name: 'linux'

    count = 0
    w = cd.watch 'name', ->
        count++

    cd.scan()
    $test.equal count, 1

    cd.scope.name = 'ubuntu'
    cd.scan()
    $test.equal count, 2

    cd.scope.name = 'debian'
    cd.scan
        skipWatch: w
    $test.equal count, 2

    cd.scan()
    $test.equal count, 2

    cd.scope.name = 'redhat'
    cd.scan()
    $test.equal count, 3

    $test.close()
