
Test('direct-directive-0').run ($test, alight) ->
    $test.start 4

    dom = ttDOM """
        <div myfunc!="name, $element, this, $env"></div>
    """

    cd = alight.ChangeDetector
        name: 'Ubuntu'
        myfunc: (name, el, scope, env) ->
            $test.equal name, cd.scope.name
            $test.equal scope, cd.scope
            $test.equal env.changeDetector, cd
            $test.equal el, dom.firstElementChild

    alight(dom, cd);
    $test.close()
