
Test('$compile#0').run ($test, alight) ->
    $test.start 4
    scope =
        foo: 'one'

    r0 = alight.utils.compile.expression 'foo',
        string: true
        rawExpression: true

    $test.equal r0.rawExpression, "(__=$$scope.foo) || (__ == null?'':__)"
    $test.equal r0.fn(scope), 'one'

    r1 = alight.utils.compile.expression 'foo',
        string: true
        rawExpression: true

    $test.equal r1.rawExpression, "(__=$$scope.foo) || (__ == null?'':__)"
    $test.equal r1.fn(scope), 'one'
    $test.close()


Test('$watchText#0', 'watch-text-0').run ($test, alight) ->
    $test.start 4
    scope =
        os:
            type: 'linux'
            name: 'ubuntu'

    cd = alight.ChangeDetector scope

    r0 = cd.watchText 'OS {{os.type}} {{os.name}}', ->

    $test.equal r0.value, 'OS linux ubuntu'
    $test.equal r0.$.exp(scope), 'OS linux ubuntu'

    r1 = cd.watchText 'OS {{os.type}} {{os.name}}', ->

    $test.equal r1.value, 'OS linux ubuntu'
    $test.equal r1.$.exp(scope), 'OS linux ubuntu'
    $test.close()
