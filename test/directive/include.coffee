
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

    cd = alight.ChangeDetector()
    cd.scope.link = 'link1'

    el = ttDOM """
        start
        <div :html.url="link"></div>
        finish
    """

    alight.bind cd, el

    $test.equal ttGetText(el), 'start finish'
    timeout.add 20, ->
        $test.equal ttGetText(el), 'start one-link1 finish'

        cd.scope.link = null
        cd.scan()
        $test.equal ttGetText(el), 'start finish'

        cd.scope.link = 'link2'
        cd.scan()
        timeout.add 20, ->
            $test.equal ttGetText(el), 'start two-link2 finish'

            $test.close()
