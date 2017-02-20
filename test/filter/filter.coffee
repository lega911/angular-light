
Test('filter-filter-0').run ($test, alight) ->
    if not alight.filters.filter
        return 'skip'
    $test.start 5

    scope =
        list: [
            { name: 'linux 1' }
            { name: 'ubuntu 2' }
            { name: 'red hat 4', k: 'kind' }
            { name: 'windows 8', k: 'kind' }
        ]
        text: ''
    cd = alight.ChangeDetector scope

    resultList = []

    cd.watch 'list | filter "name" text', (value) ->
        resultList = value
    ,
        isArray: true

    result = ->
        sum = 0
        for i in resultList
            sum += Number i.name.match(/\d+/)
        sum

    cd.scan()
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

                scope.text = 'kin'
                cd.scan ->
                    $test.equal result(), 0

                    $test.close()


Test('filter-filter-1').run ($test, alight) ->
    if not alight.filters.filter
        return 'skip'
    $test.start 5

    scope =
        list: [
            { name: 'linux 1' }
            { name: 'ubuntu 2' }
            { name: 'red hat 4', k: 'kind u' }
            { name: 'windows 8', k: 'kind' }
        ]
        text: ''
    cd = alight.ChangeDetector scope

    resultList = []

    cd.watch 'list | filter text', (value) ->
        resultList = value
    ,
        isArray: true

    result = ->
        sum = 0
        for i in resultList
            sum += Number i.name.match(/\d+/)
        sum

    cd.scan()
    $test.equal result(), 15

    scope.list.push
        name: 'macos X 16'
    scope.list.push
        name: 'freebds 32'

    cd.scan ->
        $test.equal result(), 63

        scope.text = 'u'
        cd.scan ->
            $test.equal result(), 7

            scope.text = 's'
            cd.scan ->
                $test.equal result(), 8+16+32

                scope.text = 'kin'
                cd.scan ->
                    $test.equal result(), 12

                    $test.close()


Test('filter-filter-2').run ($test, alight) ->
    if not alight.filters.filter
        return 'skip'
    $test.start 5

    scope =
        list: [
            { value: 1, st: true }
            { value: 2, st: false }
            { value: 4, st: true }
            { value: 8, st: false }
            { value: 16, st: true }
        ]
        value: null

    cd = alight.ChangeDetector scope

    resultList = []

    cd.watch 'list | filter "st" value', (value) ->
        resultList = value
    ,
        isArray: true

    result = ->
        sum = 0
        for i in resultList
            sum += i.value
        sum

    cd.scan()
    $test.equal result(), 31

    scope.value = true
    cd.scan ->
        $test.equal result(), 21

        scope.value = false
        cd.scan ->
            $test.equal result(), 10

            scope.list.push
                value: 32
                st: false

            cd.scan ->
                $test.equal result(), 42

                scope.value = null
                cd.scan ->
                    $test.equal result(), 63
                    $test.close()


Test('filter-in-class').run ($test, alight) ->
    $test.start 2
    el = ttDOM('<div :class="color | invert"></div>').children[0]

    scope =
        color: 'der'
        invert: (value) ->
            value.split('').reverse().join('')
    cd = alight el, scope

    $test.equal el.className, 'red'

    scope.color = 'eulb'
    cd.scan()
    $test.equal el.className, 'blue'

    $test.close()
