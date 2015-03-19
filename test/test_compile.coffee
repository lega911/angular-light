
Test('$compile#0').run ($test, alight) ->
    $test.start 4
    scope = alight.Scope()
    scope.foo = 'one'

    r0 = scope.$compile 'foo',
        stringOrOneTime: true
        full: true
        rawExpression: true
        noBind: true

    $test.equal r0.rawExpression, "(__=$$scope.foo) || (__ == null?'':__)"
    $test.equal r0.fn(scope), 'one'

    r1 = scope.$compile 'foo',
        stringOrOneTime: true
        full: true
        rawExpression: true
        noBind: true

    $test.equal r1.rawExpression, "(__=$$scope.foo) || (__ == null?'':__)"
    $test.equal r1.fn(scope), 'one'
    $test.close()


Test('$compileText#0').run ($test, alight) ->
    $test.start 6
    scope = alight.Scope()
    scope.os =
        type: 'linux'
        name: 'ubuntu'

    r0 = scope.$watchText 'OS {{os.type}} {{os.name}}', ->

    $test.equal r0.value, 'OS linux ubuntu'
    $test.equal r0.$.exp(scope), 'OS linux ubuntu'
    $test.equal !!r0.$.isObserved, alight.debug.useObserver

    r1 = scope.$watchText 'OS {{os.type}} {{os.name}}', ->

    $test.equal r1.value, 'OS linux ubuntu'
    $test.equal r1.$.exp(scope), 'OS linux ubuntu'
    $test.equal !!r1.$.isObserved, alight.debug.useObserver
    $test.close()
