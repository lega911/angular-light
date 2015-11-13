Test('bindonce: switch 0', 'bo-switch-0').run ($test, alight) ->
    $test.start 1


    el = document.createElement 'div'
    el.innerHTML = '''<div bo-switch="value">
                        <span bo-switch-when="two">two 2</span>
                        <span bo-switch-when="one">one 1</span>
                        <span bo-switch-default>default</span>
                    </div>'''    

    cd = alight.ChangeDetector
        value: 'one'
    alight.applyBindings cd, el

    $test.equal el.innerText.trim(), 'one 1'
    $test.close()

Test('bindonce: switch 1', 'bo-switch-1').run ($test, alight) ->
    $test.start 1


    el = document.createElement 'div'
    el.innerHTML = '''<div bo-switch="value">
                        <span bo-switch-when="two">two 2</span>
                        <span bo-switch-when="one">one 1</span>
                        <span bo-switch-default>default</span>
                    </div>'''    

    cd = alight.ChangeDetector
        value: 'three'
    alight.applyBindings cd, el

    $test.equal el.innerText.trim(), 'default'
    $test.close()
