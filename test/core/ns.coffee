
Test('$ns').run ($test, alight) ->
    $test.start 4
    f$ = alight.f$

    # ut-test3
    do ->
        tag = document.createElement 'div'
        tag.innerHTML = '<p ut-test3="linux"></p>'

        alight.directives.ut =
            test3: (cd, el, name) ->
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
                        uniqDirective: (cd, el, name) ->
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

        tag = document.createElement 'div'
        tag.innerHTML = '<p>{{0 | double}}</p>'

        cd = alight.ChangeDetector scope
        alight.applyBindings cd, tag
        $test.equal f$.text(f$.find(tag, 'p')[0]), 'linux'

        $test.close()


Test('$ns-0', 'ns-0').run ($test, alight) ->
    $test.start 2
    f$ = alight.f$


    tag = document.createElement 'div'
    tag.innerHTML = '<p al-private="title"></p>:<p al-text="title"></p>'


    scope =
        title: 'title'
        $ns:
            directives:
                al:
                    private: (cd, el, name) ->
                        f$.text el, name

    cd = alight.ChangeDetector scope
    try
        alight.applyBindings cd, tag
    catch e
        $test.equal e, 'Directive not found: al-text'

    scope.$ns.inheritGlobal = true
    alight.applyBindings cd, tag

    $test.equal f$.text(tag), 'title:title'
    $test.close()
