
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

    scope = alight.bootstrap el,
        name: 'linux'
        counter: ->
            index++

    $test.equal ttGetText(el), 'linux-1'

    scope.name = 'unix'
    scope.$scan()
    $test.equal ttGetText(el), 'unix-1 child2=unix-2'

    scope.name = 'ubuntu'
    scope.$scan()
    $test.equal ttGetText(el), 'ubuntu-1 child1=ubuntu-3 child2=ubuntu-2'

    scope.name = 'linux'
    scope.$scan()
    $test.equal ttGetText(el), 'linux-1'

    scope.name = 'mac'
    scope.$scan()
    $test.equal ttGetText(el), 'mac-1 child2=mac-4'

    $test.close()
