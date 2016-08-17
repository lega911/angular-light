
Test('hook-scope-0', 'hook-scope-0').run ($test, alight) ->
    if $test.basis
        return 'skip'
    alight.option.injectScope = true
    $test.start 27

    count0 = count1 = count2 = count3 = 0
    childScope = null

    alight.d.ut =
        dir:
            scope: 'root'
            link: (scope, element, value) ->
                childScope = scope
                scope.top = 'child'
                scope.child = 'child'
                scope.$watch 'top', ->
                    count2++
                scope.$watch '$parent.top', ->
                    count3++

    dom = ttDOM """
        <i>root={{top}}</i>
        <i ut-dir>
            child={{top}}
            <i>parent={{$parent.top}}</i>
        </i>
    """

    rootScope = alight.Scope()
    rootScope.top = 'root'
    rootScope.$watch 'top', ->
        count0++
    rootScope.$watch 'child', ->
        count1++

    alight.bind rootScope, dom
    $test.equal ttGetText(dom), 'root=root child=child parent=root'
    $test.equal count0, 1
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal count3, 1
    $test.equal rootScope.child, undefined  # isolated scope

    rootScope.top = 'tip'
    rootScope.$scan()

    $test.equal ttGetText(dom), 'root=tip child=child parent=root'  # shows that a parent doesn't influence to a child
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal count3, 1

    childScope.$scan()
    $test.equal ttGetText(dom), 'root=tip child=child parent=tip'
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal count3, 2

    childScope.$parent.top = 'fromChild'
    childScope.$scan()
    $test.equal ttGetText(dom), 'root=tip child=child parent=fromChild'  # shows that a child doesn't influence to its parent
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal count3, 3

    rootScope.$scan()
    $test.equal ttGetText(dom), 'root=fromChild child=child parent=fromChild'
    $test.equal count0, 3
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal count3, 3

    countDestroy = 0
    childScope.$watch '$destroy', ->
        countDestroy++
    ,
        root: true

    rootScope.$destroy()

    $test.equal countDestroy, 1

    $test.close()


###
Test('hook-scope-1', 'hook-scope-1').run ($test, alight) ->
    $test.start 27

    count0 = count1 = count2 = 0
    childCD = null

    alight.d.ut =
        dir:
            #scope: false
            ChangeDetector: 'root'
            link: (scope, cd, element, value) ->
                childCD = cd
                scope.top = 'child'
                scope.child = 'child'
                cd.watch 'top', ->
                    count2++

    dom = ttDOM """
        <i>root={{top}}</i>
        <i ut-dir>
            child={{top}}
        </i>
    """

    rootCD = alight.ChangeDetector
        top: 'root'
    rootCD.watch 'top', ->
        count0++
    rootCD.watch 'child', ->
        count1++

    alight.applyBindings rootCD, dom
    $test.equal ttGetText(dom), 'root=child child=child'
    $test.equal count0, 1
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal rootCD.scope.child, 'child'  # the same scope
    $test.equal childCD.$parent, undefined

    rootCD.scan()
    $test.equal ttGetText(dom), 'root=child child=child', 'scan root'
    $test.equal count0, 1
    $test.equal count1, 1
    $test.equal count2, 1


    rootCD.scope.top = 'tip'
    rootCD.scan()
    $test.equal ttGetText(dom), 'root=tip child=child', 'update root'
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 1

    childCD.scan()
    $test.equal ttGetText(dom), 'root=tip child=tip', 'scan child'
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 2

    childCD.scope.top = 'fromChild'
    childCD.scan()
    $test.equal ttGetText(dom), 'root=tip child=fromChild', 'update child'
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 3

    rootCD.scan()
    $test.equal ttGetText(dom), 'root=fromChild child=fromChild', 'scan root'
    $test.equal count0, 3
    $test.equal count1, 1
    $test.equal count2, 3

    countDestroy = 0
    childCD.watch '$destroy', ->
        countDestroy++

    rootCD.destroy()

    $test.equal countDestroy, 1

    $test.close()
###

###
Test('hook-scope-2', 'hook-scope-2').run ($test, alight) ->
    $test.start 27

    count0 = count1 = count2 = 0
    childScope = null

    alight.d.ut =
        dir:
            scope: true
            link: (scope, element, value) ->
                childScope = scope
                scope.top = 'child'
                scope.child = 'child'
                scope.$watch 'top', ->
                    count2++

    dom = ttDOM """
        <i>root={{top}}</i>
        <i ut-dir>
            child={{top}}
        </i>
    """

    rootScope = alight.Scope()
    rootScope.top = 'root'
    rootScope.$watch 'top', ->
        count0++
    rootScope.$watch 'child', ->
        count1++

    alight.bind rootScope, dom
    $test.equal ttGetText(dom), 'root=child child=child'
    $test.equal count0, 1
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal rootScope.child, 'child'  # the same scope
    $test.equal childScope.$parent, undefined

    rootScope.$scan()
    $test.equal ttGetText(dom), 'root=child child=child', 'scan root'
    $test.equal count0, 1
    $test.equal count1, 1
    $test.equal count2, 1

    rootScope.top = 'tip'
    rootScope.$scan()
    $test.equal ttGetText(dom), 'root=tip child=tip', 'update root'
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 2

    childScope.$scan()
    $test.equal ttGetText(dom), 'root=tip child=tip', 'scan child'
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 2

    childScope.top = 'fromChild'
    childScope.$scan()
    $test.equal ttGetText(dom), 'root=fromChild child=fromChild', 'update child'
    $test.equal count0, 3
    $test.equal count1, 1
    $test.equal count2, 3

    rootScope.$scan()
    $test.equal ttGetText(dom), 'root=fromChild child=fromChild', 'scan root'
    $test.equal count0, 3
    $test.equal count1, 1
    $test.equal count2, 3

    countDestroy = 0
    childScope.$watch '$destroy', ->
        countDestroy++
    ,
        root: true

    rootScope.$destroy()

    $test.equal countDestroy, 1

    $test.close()
###

###
Test('hook-scope-3', 'hook-scope-3').run ($test, alight) ->
    $test.start 27

    count0 = count1 = count2 = count3 = 0
    childCD = null

    alight.d.ut =
        dir:
            scope: true
            #ChangeDetector: true
            link: (scope, cd, element, value) ->
                childCD = cd
                scope.top = 'child'
                scope.child = 'child'
                cd.watch 'top', ->
                    count2++
                cd.watch '$parent.top', ->
                    count3++

    dom = ttDOM """
        <i>root={{top}}</i>
        <i ut-dir>
            child={{top}}
            <i>parent={{$parent.top}}</i>
        </i>
    """

    rootCD = alight.ChangeDetector
        top: 'root'
    rootCD.watch 'top', ->
        count0++
    rootCD.watch 'child', ->
        count1++

    alight.applyBindings rootCD, dom
    $test.equal ttGetText(dom), 'root=root child=child parent=root'
    $test.equal count0, 1
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal count3, 1
    $test.equal rootCD.scope.child, undefined  # isolated scope

    rootCD.scope.top = 'tip'
    rootCD.scan()
    $test.equal ttGetText(dom), 'root=tip child=child parent=tip', 'update root'
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal count3, 2

    childCD.scan()
    $test.equal ttGetText(dom), 'root=tip child=child parent=tip'
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal count3, 2

    childCD.scope.$parent.top = 'fromChild'
    childCD.scan()
    $test.equal ttGetText(dom), 'root=fromChild child=child parent=fromChild', 'update child'
    $test.equal count0, 3
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal count3, 3

    rootCD.scan()
    $test.equal ttGetText(dom), 'root=fromChild child=child parent=fromChild'
    $test.equal count0, 3
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal count3, 3

    countDestroy = 0
    childCD.watch '$destroy', ->
        countDestroy++

    rootCD.destroy()

    $test.equal countDestroy, 1

    $test.close()
###

Test('hook-scope-4').run ($test, alight) ->
    $test.start 27

    count0 = count1 = count2 = 0
    childScope = null

    alight.d.ut =
        dir:
            #scope: false
            #ChangeDetector: false
            link: (scope, element, value) ->
                childScope = scope
                scope.top = 'child'
                scope.child = 'child'
                this.watch 'top', ->
                    count2++

    dom = ttDOM """
        <i>root={{top}}</i>
        <i ut-dir>
            child={{top}}
        </i>
    """

    cd = alight.ChangeDetector()
    rootScope = cd.scope
    rootScope.top = 'root'
    cd.watch 'top', ->
        count0++
    cd.watch 'child', ->
        count1++

    alight.bind cd, dom
    $test.equal ttGetText(dom), 'root=child child=child'
    $test.equal count0, 1
    $test.equal count1, 1
    $test.equal count2, 1
    $test.equal rootScope.child, 'child'  # the same scope
    $test.equal childScope.$parent, undefined

    cd.scan()
    $test.equal ttGetText(dom), 'root=child child=child', 'scan root'
    $test.equal count0, 1
    $test.equal count1, 1
    $test.equal count2, 1  # the watch was created earlier

    rootScope.top = 'tip'
    cd.scan()
    $test.equal ttGetText(dom), 'root=tip child=tip', 'update root'
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 2

    cd.scan()
    $test.equal ttGetText(dom), 'root=tip child=tip', 'scan child'
    $test.equal count0, 2
    $test.equal count1, 1
    $test.equal count2, 2

    childScope.top = 'fromChild'
    cd.scan()
    $test.equal ttGetText(dom), 'root=fromChild child=fromChild', 'update child'
    $test.equal count0, 3
    $test.equal count1, 1
    $test.equal count2, 3

    cd.scan()
    $test.equal ttGetText(dom), 'root=fromChild child=fromChild', 'scan root'
    $test.equal count0, 3
    $test.equal count1, 1
    $test.equal count2, 3

    countDestroy = 0
    cd.watch '$destroy', ->
        countDestroy++

    cd.destroy()

    $test.equal countDestroy, 1

    $test.close()
