
Test('ns-0', 'ns-0').run ($test, alight) ->
    $test.start 4
    f$ = alight.f$

    # ut-test3
    do ->
        tag = document.createElement 'div'
        tag.innerHTML = '<p ut-test3="linux"></p>'

        alight.directives.ut =
            test3: (scope, cd, el, name) ->
                f$.text el, name

        cd = alight.ChangeDetector()
        alight.applyBindings cd, tag
        $test.equal f$.text(f$.find(tag, 'p')[0]), 'linux'

    # $ns.ut-test3
    do ->
        scope =
            $ns:
                directives:
                    ut:
                        uniqDirective: (scope, cd, el, name) ->
                            f$.text el, name

        cd = alight.ChangeDetector scope

        tag = document.createElement 'div'
        tag.innerHTML = '<p ut-test3="linux"></p>'
        try
            alight.applyBindings cd, tag
            $test.error '$ns error'
        catch e
            $test.equal e, 'Directive not found: ut-test3'

        tag = document.createElement 'div'
        tag.innerHTML = '<p ut-uniq-directive="linux"></p>'
        alight.applyBindings cd, tag
        $test.equal f$.text(f$.find(tag, 'p')[0]), 'linux'

    # filter
    do ->
        scope =
            $ns:
                filters:
                    double: ->
                        ->
                            'linux'

        tag = ttDOM '<p>{{x | double}}</p>'

        cd = alight.ChangeDetector scope
        alight.applyBindings cd, tag
        $test.equal ttGetText(tag), 'linux'

        $test.close()


Test('ns-1', 'ns-1').run ($test, alight) ->
    $test.start 2
    f$ = alight.f$

    tag = ttDOM '<p al-private="title"></p>:<p al-text="title"></p>'
    scope =
        title: 'title'
        $ns:
            directives:
                al:
                    private: (scope, cd, el, name) ->
                        f$.text el, name

    cd = alight.ChangeDetector scope
    try
        alight.applyBindings cd, tag
    catch e
        $test.equal e, 'Directive not found: al-text'


    tag = ttDOM '<p al-private="title"></p>:<p al-text="title"></p>'
    cd = alight.ChangeDetector scope

    scope.$ns.inheritGlobal = true
    alight.applyBindings cd, tag

    $test.equal f$.text(tag), 'title:title'
    $test.close()
