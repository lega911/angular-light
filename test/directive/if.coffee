
Test('al-if').run ($test, alight) ->
    $test.start 5

    index = 1
    el = ttDOM """
        <div>
            {{name}}-{{=counter()}}
            <div al-if="name=='ubuntu'">
                child1={{name}}-{{=counter()}}
            </div>
            <div al-ifnot="name=='linux'">
                child2={{name}}-{{=counter()}}
            </div>
        </div>
    """

    cd = alight.bootstrap el,
        name: 'linux'
        counter: ->
            index++

    $test.equal ttGetText(el), 'linux-1'

    cd.scope.name = 'unix'
    cd.scan()
    $test.equal ttGetText(el), 'unix-1 child2=unix-2'

    cd.scope.name = 'ubuntu'
    cd.scan()
    $test.equal ttGetText(el), 'ubuntu-1 child1=ubuntu-3 child2=ubuntu-2'

    cd.scope.name = 'linux'
    cd.scan()
    $test.equal ttGetText(el), 'linux-1'

    cd.scope.name = 'mac'
    cd.scan()
    $test.equal ttGetText(el), 'mac-1 child2=mac-4'

    $test.close()
