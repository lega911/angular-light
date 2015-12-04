
Test('ns-0', 'ns-0').run ($test, alight) ->
    $test.start 4
    f$ = alight.f$

    # ut-test3
    do ->
        el = ttDOM '<p ut-test3="linux"></p>'

        alight.directives.ut =
            test3: (scope, el, name) ->
                f$.text el, name

        alight.bootstrap el
        $test.equal ttGetText(el), 'linux'

    # $ns.ut-test3
    do ->
        scope =
            $ns:
                directives:
                    ut:
                        uniqDirective: (scope, el, name) ->
                            f$.text el, name

        try
            alight.bootstrap ttDOM('<p ut-test3="linux"></p>'), scope
            $test.error '$ns error'
        catch e
            $test.equal e, 'Directive not found: ut-test3'

        el = ttDOM '<p ut-test3="linux"></p>'
        alight.bootstrap el
        $test.equal ttGetText(el), 'linux'

    # filter
    do ->
        scope =
            $ns:
                filters:
                    double: ->
                        ->
                            'linux'

        el = ttDOM '<p>{{x | double}}</p>'

        alight.bootstrap el, scope
        $test.equal ttGetText(el), 'linux'

        $test.close()


Test('ns-1', 'ns-1').run ($test, alight) ->
    $test.start 2
    f$ = alight.f$

    tag = ttDOM '<p al-private="title"></p>:<p al-text="title"></p>'
    makeScope = ->
        title: 'title'
        $ns:
            directives:
                al:
                    private: (scope, el, name) ->
                        f$.text el, name

    try
        alight.bootstrap tag, makeScope()
    catch e
        $test.equal e, 'Directive not found: al-text'


    tag = ttDOM '<p al-private="title"></p>:<p al-text="title"></p>'

    scope = makeScope()
    scope.$ns.inheritGlobal = true
    alight.bootstrap tag, scope

    $test.equal ttGetText(tag), 'title:title'
    $test.close()
