Test('filter slice', 'filter-slice').run ($test, alight) ->
    $test.start 4
    scope =
        lst: [0,1,2,3,4,5,6,7,8,9]
        a: 7
        b: 15

    result = null
    result2 = null

    cd = alight.ChangeDetector scope
    cd.watch 'lst | slice:a', (value) ->
        result = value
    ,
        isArray: true
        init: true
    cd.watch 'lst | slice:a,b', (value) ->
        result2 = value
    ,
        isArray: true
        init: true

    equal = (a, b) ->
        if a.length isnt b.length
            console.error a, b
            return false
        for v, i in a
            if v isnt b[i]
                console.error a, b
                return false
        true

    cd.scan ->
        $test.check equal(result, [7,8,9])
        $test.check equal(result2, [7,8,9])

        scope.a = 3
        scope.b = 6
        cd.scan ->
            $test.check equal(result, [3,4,5,6,7,8,9])
            $test.check equal(result2, [3,4,5])
            $test.close()


Test('filter date', 'filter-date').run ($test, alight) ->
    $test.start 9
    scope =
        value: null
    cd = alight.ChangeDetector scope

    r0 = ''
    r1 = ''
    r2 = ''
    cd.watch 'value | date:yyyy-mm-dd', (value) ->
        r0 = value
    cd.watch 'value | date:HH:MM:SS', (value) ->
        r1 = value
    cd.watch 'value | date:yyyy-mm-dd HH:MM:SS', (value) ->
        r2 = value

    cd.scan ->
        $test.equal r0, ''
        $test.equal r1, ''
        $test.equal r2, ''

        scope.value = new Date(2014, 5, 13, 3, 44, 55);
        cd.scan ->
            $test.equal r0, '2014-06-13'
            $test.equal r1, '03:44:55'
            $test.equal r2, '2014-06-13 03:44:55'

            scope.value = new Date(1995, 0, 31, 23, 59, 59);
            cd.scan ->
                $test.equal r0, '1995-01-31'
                $test.equal r1, '23:59:59'
                $test.equal r2, '1995-01-31 23:59:59'
                $test.close()


Test('$filter async #0', 'filter-async-0').run ($test, alight) ->
    $test.start 57

    fdouble = 0
    fadd = 0
    alight.filters.double = (exp, cd, env) ->
        (value) ->
            fdouble++
            value + value

    alight.filters.add = (exp, cd, env) ->
        (value) ->
            fadd++
            value + exp.trim()

    setters = []
    async = []
    result0 = []
    result1 = []
    result2 = []
    alight.filters.get = (exp, cd, env) ->
        setters.push env.setValue
        onChange: (value) ->
            async.push value

    scope =
        value: 'one'
    cd = alight.ChangeDetector scope
    cd.watch 'value | double | get | add:EX', (value) ->
        result0.push value

    $test.equal fdouble, 0
    $test.equal fadd, 0
    $test.equal result0.length, 0
    $test.equal setters.length, 1
    $test.equal async.length, 0

    w1 = cd.watch 'value | add:PRE | get | double', (value) ->
        result1.push value

    cd.watch 'value | add:BEGIN | double | add:END', (value) ->
        result2.push value
    ,
        init: true

    $test.equal fdouble, 1
    $test.equal fadd, 2
    $test.equal result0.length, 0
    $test.equal result1.length, 0
    $test.equal result2.length, 1
    $test.equal result2[0], 'oneBEGINoneBEGINEND'
    $test.equal setters.length, 2
    $test.equal async.length, 0

    w1.fire()
    $test.equal fadd, 3
    $test.equal async.length, 1
    $test.equal async[0], 'onePRE'

    cd.scan ->
        $test.equal fdouble, 1, 'scan0'
        $test.equal fadd, 3
        $test.equal result0.length, 0
        $test.equal result1.length, 0
        $test.equal result2.length, 1
        $test.equal setters.length, 2
        $test.equal async.length, 1
        async.length = 0

        scope.value = 'two'
        cd.scan ->
            $test.equal fdouble, 3, '# step 2'
            $test.equal fadd, 6
            $test.equal result0.length, 0
            $test.equal result1.length, 0
            $test.equal result2.length, 2
            $test.equal result2[1], 'twoBEGINtwoBEGINEND'
            $test.equal setters.length, 2
            $test.equal async.length, 2
            $test.equal async.indexOf('twotwo')>=0, true
            $test.equal async.indexOf('twoPRE')>=0, true
            async.length = 0

            alight.nextTick ->
                setters[0] 'async-two'
                cd.scan ->

                    $test.equal fdouble, 3, '# step 3'
                    $test.equal fadd, 7
                    $test.equal result0.length, 1
                    $test.equal result0[0], 'async-twoEX'
                    $test.equal result1.length, 0
                    $test.equal result2.length, 2
                    $test.equal setters.length, 2
                    $test.equal async.length, 0

                    setters[1] 'async-three'
                    cd.scan ->

                        $test.equal fdouble, 4, '# step 4'
                        $test.equal fadd, 7
                        $test.equal result0.length, 1
                        $test.equal result1.length, 1
                        $test.equal result1[0], 'async-threeasync-three'
                        $test.equal result2.length, 2
                        $test.equal setters.length, 2
                        $test.equal async.length, 0

                        setters[1] 'async-four'
                        cd.scan ->

                            $test.equal fdouble, 5, '# step 5'
                            $test.equal fadd, 7
                            $test.equal result0.length, 1
                            $test.equal result1.length, 2
                            $test.equal result1[1], 'async-fourasync-four'
                            $test.equal result2.length, 2
                            $test.equal setters.length, 2
                            $test.equal async.length, 0

                            $test.close()

Test('$filter async #1', 'filter-async-1').run ($test, alight) ->
    $test.start 4

    alight.filters.foo = (exp, scope, env) ->
        onChange: (value) ->
            r = value.slice()
            r.push 'E'
            env.setValue r

    scope =
        list: [1,2,3,4,5,6,7,8,9]

    rcount = 0
    rlen = 0
    cd = alight.ChangeDetector scope
    w = cd.watch 'list | slice:2,5 | foo', (value) ->
        rcount++
        rlen = value.length

    $test.equal rcount, 0
    $test.equal rlen, 0

    w.fire()
    $test.equal rcount, 1
    $test.equal rlen, 4

    $test.close()


Test('$filter async #2', 'filter-async-2').run ($test, alight, timeout) ->
    $test.start 14

    rdestroy = 0
    alight.filters.foo = (exp, cd, env) ->
        value = null
        active = true
        setter = ->
            if not active
                return
            timeout.add 100, setter
            env.setValue value
        timeout.add 100, setter

        cd.watch '$destroy', ->
            rdestroy++
            active = false

        onChange: (input) ->
            value = input

    scope =
        r: 'one'

    rcount = 0
    rvalue = ''
    cd = alight.ChangeDetector scope
    w = cd.watch 'r | foo', (value) ->
        rcount++
        rvalue = value

    $test.equal rcount, 0
    $test.equal rvalue, ''

    w.fire()
    $test.equal rcount, 0
    $test.equal rvalue, ''

    timeout.add 150, ->
        $test.equal rcount>0, true
        $test.equal rvalue, 'one'
        rcount = 0

        scope.r = 'two'
        timeout.add 100, ->
            $test.equal rcount>0, true
            $test.equal rvalue, 'one'
            rcount = 0

            cd.scan ->
                timeout.add 100, ->
                    $test.equal rcount>0, true
                    $test.equal rvalue, 'two'
                    rcount = 0

                    scope.r = 'three'
                    cd.destroy()
                    $test.equal rdestroy, 1
                    timeout.add 200, ->
                        $test.equal rcount, 0
                        $test.equal rvalue, 'two'
                        $test.equal rdestroy, 1

                        $test.close()


Test('async filter + watchText #0', 'async-filter-watch-text-0').run ($test, alight, timeout) ->
    $test.start 24

    alight.filters.foo = (exp, scope, env) ->
        (value) ->
            rfoo++
            value+':'+value

    alight.filters.get = (exp, scope, env) ->
        onChange: (value) ->
            rasync++
            timeout.add 10, ->
                env.setValue value + ':async'

    scope =
        value: 'one'

    rfoo = 0
    rasync = 0
    rcount = 0
    rvalue = ''

    cd = alight.ChangeDetector scope
    cd.watchText 'pre {{value | foo | get}} fix', (value) ->
        rcount++
        rvalue = value
    ,
        init: true

    $test.equal rfoo, 1
    $test.equal rasync, 1
    $test.equal rcount, 1
    $test.equal rvalue, 'pre  fix'

    cd.scan ->
        $test.equal rfoo, 1
        $test.equal rasync, 1
        $test.equal rcount, 1
        $test.equal rvalue, 'pre  fix'

        timeout.add 15, ->
            $test.equal rfoo, 1
            $test.equal rasync, 1
            $test.equal rcount, 1
            $test.equal rvalue, 'pre  fix'

            cd.scan ->
                $test.equal rfoo, 1
                $test.equal rasync, 1
                $test.equal rcount, 2
                $test.equal rvalue, 'pre one:one:async fix'

                scope.value = 'two'
                cd.scan ->
                    $test.equal rfoo, 2
                    $test.equal rasync, 2
                    $test.equal rcount, 2
                    $test.equal rvalue, 'pre one:one:async fix'

                    timeout.add 15, ->
                        cd.scan ->
                            $test.equal rfoo, 2
                            $test.equal rasync, 2
                            $test.equal rcount, 3
                            $test.equal rvalue, 'pre two:two:async fix'

                        $test.close()


Test('filter json', 'filter-json').run ($test, alight) ->
    $test.start 2
    scope =
        data:
            name: 'linux'

    result = ''

    cd = alight.ChangeDetector scope
    cd.watch 'data | json', (value) ->
        result = value
    ,
        init: true

    getr = ->
        result.replace /\s/g, ''

    $test.equal getr(), '{"name":"linux"}'

    cd.scan ->
        scope.data.name = 'ubuntu'
        cd.scan ->
            $test.equal getr(), '{"name":"ubuntu"}'

            $test.close()


Test('filter filter', 'filter-filter').run ($test, alight) ->
    $test.start 5

    scope =
        list: [
            { name: 'linux 1' }
            { name: 'ubuntu 2' }
            { name: 'red hat 4', k: 'kind' }
            { name: 'windows 8', k: 'kind' }
        ]
    scope.text = ''

    resultList = []

    cd = alight.ChangeDetector scope
    cd.watch 'list | filter:text', (value) ->
        resultList = value
    ,
        isArray: true
        init: true

    result = ->
        sum = 0
        for i in resultList
            sum += Number i.name.match(/\d+/)
        sum

    $test.equal result(), 15    

    scope.list.push
        name: 'macos X 16'
    scope.list.push
        name: 'freebds 32'

    cd.scan ->
        $test.equal result(), 63

        scope.text = 'u'
        cd.scan ->
            $test.equal result(), 3

            scope.text = 's'
            cd.scan ->
                $test.equal result(), 8+16+32

                scope.text =
                    k: 'kind'
                cd.scan ->
                    $test.equal result(), 12

                    $test.close()


Test('$filter async #3', 'filter-async-3').run ($test, alight, timeout) ->
    $test.start 25

    fooInited = 0
    fooStep = 0
    fooChange = 0
    fooStop = 0
    fooDestroy = 0
    alight.filters.foo = (exp, cd, env) ->
        fooInited++
        active = true
        value = 0
        step = ->
            fooStep++
            value++
            env.setValue '#' + value
            if active
                timeout.add 100, step
        timeout.add 100, step

        cd.watch '$destroy', ->
            fooDestroy++
            active = false

        onChange: (input) ->
            value = input
            fooChange++
        onStop: ->
            active = false
            fooStop++

    c0 = 0
    v0 = null
    scope =
        one: 5

    cd = alight.ChangeDetector scope
    w = cd.watch '::one | foo', (value) ->
        c0++
        v0 = value

    $test.equal c0, 0
    $test.equal v0, null
    $test.equal fooInited, 1
    $test.equal fooStep, 0
    $test.equal fooChange, 0
    $test.equal fooStop, 0
    $test.equal fooDestroy, 0

    timeout.add 105, ->
        $test.equal fooStep, 1
        $test.equal c0, 1
        $test.equal v0, '#1'
        $test.equal fooChange, 0

        w.fire()
        $test.equal fooStep, 1
        $test.equal fooChange, 1
        $test.equal fooStop, 1, 'fooStop'

        timeout.add 100, ->
            $test.equal fooStep, 2
            $test.equal c0, 2
            $test.equal v0, '#6'
            $test.equal fooChange, 1

            cd.destroy()

            timeout.add 100, ->
                $test.equal c0, 2
                $test.equal v0, '#6'
                $test.equal fooInited, 1
                $test.equal fooStep, 2
                $test.equal fooChange, 1
                $test.equal fooStop, 1
                $test.equal fooDestroy, 1

                $test.close()


Test('$filter async #4', 'filter-async-4').run ($test, alight, timeout) ->
    $test.start 4

    fooStop = 0
    count = 0
    alight.filters.foo = (exp, cd, env) ->
        onChange: (input) ->
            env.setValue '#' + input
        onStop: ->
            fooStop++

    cd = alight.ChangeDetector
        one: 5
    w = cd.watch 'one | foo', ->
        count++
    ,
        init: true

    cd.scan ->
        $test.equal count, 1
        $test.equal fooStop, 0

        cd.destroy()
        $test.equal count, 1
        $test.equal fooStop, 1

        $test.close()
