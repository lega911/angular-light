Test('filter slice', 'filter-slice').run ($test, alight) ->
    $test.start 4
    scope = alight.Scope()
    scope.lst = [0,1,2,3,4,5,6,7,8,9];
    scope.a = 7;
    scope.b = 15;

    result = null
    result2 = null
    scope.$watch 'lst | slice:a', (value) ->
        result = value
    ,
        isArray: true
        init: true
    scope.$watch 'lst | slice:a,b', (value) ->
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

    scope.$scan ->
        $test.check equal(result, [7,8,9])
        $test.check equal(result2, [7,8,9])

        scope.a = 3
        scope.b = 6
        scope.$scan ->
            $test.check equal(result, [3,4,5,6,7,8,9])
            $test.check equal(result2, [3,4,5])
            $test.close()


Test('filter date', 'filter-date').run ($test, alight) ->
    $test.start 9
    scope = alight.Scope()
    scope.value = null

    r0 = ''
    r1 = ''
    r2 = ''
    scope.$watch 'value | date:yyyy-mm-dd', (value) ->
        r0 = value
    scope.$watch 'value | date:HH:MM:SS', (value) ->
        r1 = value
    scope.$watch 'value | date:yyyy-mm-dd HH:MM:SS', (value) ->
        r2 = value

    scope.$scan ->
        $test.equal r0, ''
        $test.equal r1, ''
        $test.equal r2, ''

        scope.value = new Date(2014, 5, 13, 3, 44, 55);
        scope.$scan ->
            $test.equal r0, '2014-06-13'
            $test.equal r1, '03:44:55'
            $test.equal r2, '2014-06-13 03:44:55'

            scope.value = new Date(1995, 0, 31, 23, 59, 59);
            scope.$scan ->
                $test.equal r0, '1995-01-31'
                $test.equal r1, '23:59:59'
                $test.equal r2, '1995-01-31 23:59:59'
                $test.close()


Test('$filter async #0', 'filter-async-0').run ($test, alight) ->
    $test.start 57

    fdouble = 0
    fadd = 0
    alight.filters.double = (exp, scope, env) ->
        (value) ->
            fdouble++
            value + value

    alight.filters.add = (exp, scope, env) ->
        (value) ->
            fadd++
            value + exp.trim()

    setters = []
    async = []
    result0 = []
    result1 = []
    result2 = []
    alight.filters.get = (exp, scope, env) ->
        setters.push env.setValue
        onChange: (value) ->
            async.push value

    scope = alight.Scope()
    scope.value = 'one'
    scope.$watch 'value | double | get | add:EX', (value) ->
        result0.push value

    $test.equal fdouble, 0
    $test.equal fadd, 0
    $test.equal result0.length, 0
    $test.equal setters.length, 1
    $test.equal async.length, 0

    w1 = scope.$watch 'value | add:PRE | get | double', (value) ->
        result1.push value

    scope.$watch 'value | add:BEGIN | double | add:END', (value) ->
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

    scope.$scan ->
        $test.equal fdouble, 1, 'scan0'
        $test.equal fadd, 3
        $test.equal result0.length, 0
        $test.equal result1.length, 0
        $test.equal result2.length, 1
        $test.equal setters.length, 2
        $test.equal async.length, 1
        async.length = 0

        scope.value = 'two'
        scope.$scan ->
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
                scope.$scan ->

                    $test.equal fdouble, 3, '# step 3'
                    $test.equal fadd, 7
                    $test.equal result0.length, 1
                    $test.equal result0[0], 'async-twoEX'
                    $test.equal result1.length, 0
                    $test.equal result2.length, 2
                    $test.equal setters.length, 2
                    $test.equal async.length, 0

                    setters[1] 'async-three'
                    scope.$scan ->

                        $test.equal fdouble, 4, '# step 4'
                        $test.equal fadd, 7
                        $test.equal result0.length, 1
                        $test.equal result1.length, 1
                        $test.equal result1[0], 'async-threeasync-three'
                        $test.equal result2.length, 2
                        $test.equal setters.length, 2
                        $test.equal async.length, 0

                        setters[1] 'async-four'
                        scope.$scan ->

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

    scope = alight.Scope()

    scope.list = [1,2,3,4,5,6,7,8,9]

    rcount = 0
    rlen = 0
    w = scope.$watch 'list | slice:2,5 | foo', (value) ->
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
    alight.filters.foo = (exp, scope, env) ->
        value = null
        active = true
        setter = ->
            if not active
                return
            timeout.add 100, setter
            env.setValue value
        timeout.add 100, setter

        scope.$watch '$destroy', ->
            rdestroy++
            active = false

        onChange: (input) ->
            value = input

    scope = alight.Scope()

    scope.r = 'one'

    rcount = 0
    rvalue = ''
    w = scope.$watch 'r | foo', (value) ->
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

            scope.$scan ->
                timeout.add 100, ->
                    $test.equal rcount>0, true
                    $test.equal rvalue, 'two'
                    rcount = 0

                    scope.r = 'three'
                    scope.$destroy()
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

    scope = alight.Scope()
    scope.value = 'one'

    rfoo = 0
    rasync = 0
    rcount = 0
    rvalue = ''
    scope.$watchText 'pre {{value | foo | get}} fix', (value) ->
        rcount++
        rvalue = value
    ,
        init: true

    $test.equal rfoo, 1
    $test.equal rasync, 1
    $test.equal rcount, 1
    $test.equal rvalue, 'pre  fix'

    scope.$scan ->
        $test.equal rfoo, 1
        $test.equal rasync, 1
        $test.equal rcount, 1
        $test.equal rvalue, 'pre  fix'

        timeout.add 15, ->
            $test.equal rfoo, 1
            $test.equal rasync, 1
            $test.equal rcount, 1
            $test.equal rvalue, 'pre  fix'

            scope.$scan ->
                $test.equal rfoo, 1
                $test.equal rasync, 1
                $test.equal rcount, 2
                $test.equal rvalue, 'pre one:one:async fix'

                scope.value = 'two'
                scope.$scan ->
                    $test.equal rfoo, 2
                    $test.equal rasync, 2
                    $test.equal rcount, 2
                    $test.equal rvalue, 'pre one:one:async fix'

                    timeout.add 15, ->
                        scope.$scan ->
                            $test.equal rfoo, 2
                            $test.equal rasync, 2
                            $test.equal rcount, 3
                            $test.equal rvalue, 'pre two:two:async fix'

                        $test.close()


Test('filter json', 'filter-json').run ($test, alight) ->
    $test.start 2
    scope = alight.Scope()
    scope.data =
        name: 'linux'

    result = ''
    scope.$watch 'data | json', (value) ->
        result = value
    ,
        init: true

    getr = ->
        result.replace /\s/g, ''

    $test.equal getr(), '{"name":"linux"}'

    scope.$scan ->
        scope.data.name = 'ubuntu'
        scope.$scan ->
            $test.equal getr(), '{"name":"ubuntu"}'

            $test.close()


Test('filter filter', 'filter-filter').run ($test, alight) ->
    $test.start 5

    scope = alight.Scope()
    scope.list = [
        { name: 'linux 1' }
        { name: 'ubuntu 2' }
        { name: 'red hat 4', k: 'kind' }
        { name: 'windows 8', k: 'kind' }
    ]
    scope.text = ''

    resultList = []
    scope.$watch 'list | filter:text', (value) ->
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

    scope.$scan ->
        $test.equal result(), 63

        scope.text = 'u'
        scope.$scan ->
            $test.equal result(), 3

            scope.text = 's'
            scope.$scan ->
                $test.equal result(), 8+16+32

                scope.text =
                    k: 'kind'
                scope.$scan ->
                    $test.equal result(), 12

                    $test.close()

