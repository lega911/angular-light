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


Test('$compile filter').run ($test, alight) ->
    $test.start 8

    alight.filters.double = ->
        (value) ->
            value + value
    
    scope = alight.Scope()
    scope.value = null

    a = scope.$compile 'value | date:yyyy-mm-dd',
        noBind: true
    b = scope.$compile 'value | date:yyyy-mm-dd',
        noBind: false
    a2 = scope.$compile 'value | date:yyyy-mm-dd | double',
        noBind: true
    b2 = scope.$compile 'value | date:yyyy-mm-dd | double',
        noBind: false

    $test.equal a(scope), ''
    $test.equal b(), ''
    $test.equal a2(scope), ''
    $test.equal b2(), ''

    scope.value = new Date(2014, 5, 13, 3, 44, 55);

    $test.equal a(scope), '2014-06-13'
    $test.equal b(), '2014-06-13'
    $test.equal a2(scope), '2014-06-132014-06-13'
    $test.equal b2(), '2014-06-132014-06-13'
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
