
Test('component-0').run ($test, alight, timeout) ->
    $test.start 2

    el = ttDOM '''<test-comp :prop="value" @fire="check($value)"></test-comp>'''

    alight.component 'test-comp', (scope) ->
        template: 'x-{{prop}}-x'
        onStart: ->
            $test.equal ttGetText(el), 'x-linux-x'
            timeout.add 10, =>
                scope.$sendEvent 'fire', 'ok'

    alight el,
        value: 'linux'
        check: (value) ->
            $test.equal value, 'ok'
            $test.close()


Test('component-1').run ($test, alight, timeout) ->
    $test.start 1

    el = ttDOM '''<comp #comp :title="linux" name="OS"></comp>'''

    alight.component 'comp', (scope) ->
        template: '{{name}}+{{title}}'
        props:
            title: 'copy'
            name: true
        api:
            check: ->
                $test.equal ttGetText(el), 'OS+linux'

    scope = {}
    alight el, scope

    scope.comp.check()
    $test.close()


Test('component-2').run ($test, alight, timeout) ->
    $test.start 2

    el = ttDOM '''<comp :api="comp" :title="value" name="OS"></comp>'''

    alight.component 'comp', (scope) ->
        template: '{{name}}+{{title}}'
        props: ['title', 'name']

    cd = alight el,
        value: 'linux'

    $test.equal ttGetText(el), 'OS+linux'
    cd.scope.value = 'Ubuntu'
    cd.scan()
    $test.equal ttGetText(el), 'OS+Ubuntu'
    $test.close()
