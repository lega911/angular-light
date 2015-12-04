Test('bo-switch-0').run ($test, alight) ->
    $test.start 1

    el = ttDOM '''<div bo-switch="value">
                        <span bo-switch-when="two">two 2</span>
                        <span bo-switch-when="one">one 1</span>
                        <span bo-switch-default>default</span>
                    </div>'''    

    alight.bootstrap el, 
        value: 'one'
    
    $test.equal el.innerText.trim(), 'one 1'
    $test.close()

Test('bo-switch-1').run ($test, alight) ->
    $test.start 1

    el = ttDOM '''<div bo-switch="value">
                        <span bo-switch-when="two">two 2</span>
                        <span bo-switch-when="one">one 1</span>
                        <span bo-switch-default>default</span>
                    </div>'''    

    alight.bootstrap el,
        value: 'three'

    $test.equal el.innerText.trim(), 'default'
    $test.close()

Test('bo-if-0').run ($test, alight) ->
    $test.start 1

    el = ttDOM '''<span bo-ifnot="v==='one'">other</span>
                    <span bo-if="v==='one'">one one</span>'''    

    alight.bootstrap el,
        v: 'one'

    $test.equal el.innerText.trim(), 'one one'
    $test.close()
