
Test('al-include').run ($test, alight, timeout) ->
    $test.start 4

    alight.f$.ajax = (option) ->
        if option.url is 'link1'
            timeout.add 10, ->
                option.success 'one-{{link}}'
        else if option.url is 'link2'
            timeout.add 10, ->
                option.success 'two-{{link}}'
        else option.error()

    scope = alight.Scope()
    scope.link = 'link1'

    el = ttDOM """
        start
        <div al-include="link"></div>
        finish
    """

    alight.bind scope, el

    $test.equal ttGetText(el), 'start finish'
    timeout.add 20, ->
        $test.equal ttGetText(el), 'start one-link1 finish'

        scope.link = null
        scope.$scan()
        $test.equal ttGetText(el), 'start finish'

        scope.link = 'link2'
        scope.$scan()
        timeout.add 20, ->
            $test.equal ttGetText(el), 'start two-link2 finish'

            $test.close()
