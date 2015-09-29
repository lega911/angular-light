
Test('$ns').run ($test, alight) ->
    $test.start 5
    f$ = alight.f$

    # ut-test3
    do ->
        tag = document.createElement 'div'
        tag.innerHTML = '<p ut-test3="linux"></p>'

        alight.directives.ut =
            test3: (el, name, scope) ->
                f$.text el, name

        scope = alight.Scope()
        alight.applyBindings scope, tag
        $test.equal f$.text(f$.find(tag, 'p')[0]), 'linux'

    # $ns.ut-test3
    do ->
        scope = alight.Scope()
        scope.$ns =
            directives:
                ut: {}
        scope.$ns.directives.ut.uniqDirective = (el, name, scope) ->
            f$.text el, name

        tag = document.createElement 'div'
        tag.innerHTML = '<p ut-test3="linux"></p>'
        try
            alight.applyBindings scope, tag
            $test.error '$ns error'
        catch e
            $test.equal e, 'Directive not found: ut-test3'

        tag = document.createElement 'div'
        tag.innerHTML = '<p ut-uniq-directive="linux"></p>'
        alight.applyBindings scope, tag
        $test.equal f$.text(f$.find(tag, 'p')[0]), 'linux'

    # filter
    do ->
        scope = alight.Scope()
        scope.$ns =
            filters: {}
        scope.$ns.filters.double = ->
            ->
                'linux'

        tag = document.createElement 'div'
        tag.innerHTML = '<p>{{0 | double}}</p>'
        alight.applyBindings scope, tag
        $test.equal f$.text(f$.find(tag, 'p')[0]), 'linux'

    # controller
    do ->
        alight.controllers.test0ctrl = ->

        scope = alight.Scope()
        scope.$ns =
            controllers: {}
            directives:
                al:
                    controller: alight.directives.al.controller
        scope.$ns.controllers.test0ctrl = (scope) ->
            scope.uniqTest = 'linux'

        tag = document.createElement 'div'
        tag.innerHTML = '<p al-controller="test0ctrl">{{uniqTest}}</p>'
        alight.applyBindings scope, tag
        $test.equal f$.text(f$.find(tag, 'p')[0]), 'linux'
        
        $test.close()


Test('$ns-0', 'ns-0').run ($test, alight) ->
    $test.start 2
    f$ = alight.f$


    tag = document.createElement 'div'
    tag.innerHTML = '<p al-private="title"></p>:<p al-text="title"></p>'


    scope = alight.Scope()
    scope.title = 'title'
    scope.$ns =
        directives:
            al:
                private: (el, name) ->
                    f$.text el, name

    try
        alight.applyBindings scope, tag
    catch e
        $test.equal e, 'Directive not found: al-text'

    scope.$ns.inheritGlobal = true
    alight.applyBindings scope, tag

    $test.equal f$.text(tag), 'title:title'
    $test.close()
