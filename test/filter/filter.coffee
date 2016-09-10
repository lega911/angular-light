
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

    cd.watch 'list | filter text "name"', (value) ->
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
