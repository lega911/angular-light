
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
    $test.start 12
    scope = alight.Scope()
    scope.os =
        type: 'linux'
        name: 'ubuntu'

    r0 = scope.$compileText 'OS {{os.type}} {{os.name}}',
        result_on_static: true
        onStatic: true
        fullResponse: true

    $test.equal r0.type, 'fn'
    $test.equal r0.fn(scope), 'OS linux ubuntu'
    $test.equal r0.isSimple, true
    $test.equal r0.simpleVariables.length, 2
    $test.equal r0.simpleVariables[0], 'os.type'
    $test.equal r0.simpleVariables[1], 'os.name'

    r1 = scope.$compileText 'OS {{os.type}} {{os.name}}',
        result_on_static: true
        onStatic: true
        fullResponse: true

    $test.equal r1.type, 'fn'
    $test.equal r1.fn(scope), 'OS linux ubuntu'
    $test.equal r1.isSimple, true
    $test.equal r1.simpleVariables.length, 2
    $test.equal r1.simpleVariables[0], 'os.type'
    $test.equal r1.simpleVariables[1], 'os.name'
    $test.close()
