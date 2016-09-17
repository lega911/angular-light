
Test('direct-directive-0').run ($test, alight) ->
    alight.option.injectScope = true
    $test.start 1

    dom = ttDOM """
        <div myfunc!="name, $element, this, $env"></div>
    """

    cd = alight.ChangeDetector
        name: 'Ubuntu'
        myfunc: (name) ->
            $test.equal name, cd.scope.name

    alight(dom, cd);
    $test.close()
