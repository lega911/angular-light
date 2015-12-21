
Test('al-ctrl').run ($test, alight) ->
    $test.start 9

    el = ttDOM """
        <span al-test0></span>
        <div al-ctrl='one'>
            <span al-test1></span>
            <div al-ctrl='two'>
                <span al-test2></span>
            </div>
        </div>"""

    alight.ctrl.one = class T
        constructor: ->
            @.val = 'parent'
            $test.equal @.method(), 'method ok', '/1'
        method: ->
            'method ok'

    alight.ctrl.two = (scope) ->
        scope.val = 'child'

    scope0 = null
    scope1 = null

    alight.d.al.test0 = (scope) ->
        scope0 = scope
        $test.equal scope.$parent, undefined, '/2'
        $test.equal scope.val, undefined

    alight.d.al.test1 = (scope) ->
        scope1 = scope
        $test.equal scope.$parent, scope0, '/4'
        $test.equal scope.val, 'parent'
        $test.equal scope.method(), 'method ok'

    alight.d.al.test2 = (scope) ->
        $test.equal scope.$parent, scope1
        $test.equal scope.val, 'child'
        $test.equal scope.$parent.method(), 'method ok'

    alight.bootstrap el

    $test.close()


Test('al-app-0').run ($test, alight) ->
    $test.start 2

    el = ttDOM """<div al-app="main">
                    <span al-test></span>
                </div>
                """

    alight.ctrl.main = class M
        constructor: ->
            @.val = 'linux'
        method: ->
            'method ok'

    alight.d.al.test = (scope) ->
        $test.equal scope.val, 'linux'
        $test.equal scope.method(), 'method ok'

    alight.bootstrap el.childNodes[0]

    $test.close()


Test('al-app-1').run ($test, alight) ->
    $test.start 2

    el = ttDOM """<div al-app="main">
                    <span al-test></span>
                </div>
                """

    alight.ctrl.main = (scope) ->
        scope.val = 'linux'
        scope.method = ->
            'method ok'

    alight.d.al.test = (scope) ->
        $test.equal scope.val, 'linux'
        $test.equal scope.method(), 'method ok'

    alight.bootstrap el.childNodes[0]

    $test.close()
