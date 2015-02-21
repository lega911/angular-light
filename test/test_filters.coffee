Test('filter slice').run ($test, alight) ->
    $test.start 4
    scope = alight.Scope()
    scope.lst = [0,1,2,3,4,5,6,7,8,9];
    scope.a = 7;
    scope.b = 15;

    result = null
    result2 = null
    scope.$watch 'lst | slice:a', (value) ->
        result = value
    , { isArray: true, init: true }
    scope.$watch 'lst | slice:a,b', (value) ->
        result2 = value
    , { isArray: true, init: true }

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


Test('filter date').run ($test, alight) ->
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
