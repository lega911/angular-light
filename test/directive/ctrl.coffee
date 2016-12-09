###
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


Test('al-ctrl-1').run ($test, alight) ->
    $test.start 1

    el = ttDOM """
        <div al-ctrl>
            A{{value}}A
            <span al-set="1"></span>
        </div>
        <div al-ctrl>
            B{{value}}B
            <span al-set="2"></span>
        </div>
    """

    alight.d.al.set = (scope, _, value) ->
        scope.value = value

    alight.bootstrap el

    $test.equal ttGetText(el), 'A1A B2B'

    $test.close()
###

Test('al-app-0').run ($test, alight) ->
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

    alight el.childNodes[0]

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

###
Test('al-ctrl-2').run ($test, alight) ->
    if $test.basis
        return 'skip'
    alight.option.injectScope = true
    $test.start 3

    el = ttDOM """
        root={{value}}
        <div al-ctrl="mainCtrl">
            child={{value}}
        </div>
    """

    scope = alight.Scope()
    scope.value = 'ROOT'
    child = null

    alight.ctrl.mainCtrl = class
        constructor: ->
            @.value = 'CHILD'
            child = @
        method: ->

    alight.bind scope, el

    $test.equal ttGetText(el), 'root=ROOT child=CHILD'

    scope.value = 'top'
    child.value = 'bot'
    scope.$scan()
    $test.equal ttGetText(el), 'root=top child=bot'

    scope.value = 'up'
    child.value = 'down'
    child.$scan()
    $test.equal ttGetText(el), 'root=up child=down'

    $test.close()
###