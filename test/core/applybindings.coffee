
Test('apply_bindings', 'apply-binding-0').run ($test, alight) ->
    $test.start 12
    f$ = alight.f$

    el = document.createElement('div')
    count = 0
    scope =
        link: 'img.jpg'
        redClass: false
        testInit: ->
            count += 1

    cd = alight.ChangeDetector scope

    f$.attr el, 'al-init', 'testInit()'
    f$.attr el, 'al-css', 'red: redClass'
    f$.attr el, 'al-src', 'some-{{link}}'
    f$.attr el, 'some-text', 'start:{{link}}:finish'
    alight.applyBindings cd, el

    $test.equal el.className, ''
    $test.equal f$.attr el, 'src', 'some-img.jpg'
    $test.equal count, 1
    $test.equal f$.attr el, 'some-text', 'start:img.jpg:finish'

    cd.scan ->
        $test.equal el.className, ''
        $test.equal f$.attr el, 'src', 'some-img.jpg'
        $test.equal count, 1
        $test.equal f$.attr el, 'some-text', 'start:img.jpg:finish'

        scope.redClass = true
        scope.link = 'other.png'
        cd.scan ->
            $test.equal el.className, 'red'
            $test.equal f$.attr el, 'src', 'some-other.png'
            $test.equal count, 1
            $test.equal f$.attr el, 'some-text', 'start:other.png:finish'

            $test.close()


Test('bootstrap-el').run ($test, alight) ->
    $test.start 4

    el = ttDOM "<div>{{name}}</div>"

    cd = alight.bootstrap el,
        name: 'Some text'
        click: ->
            @.name = 'Hello'

    scope = cd.scope
    $test.equal scope.name, 'Some text'
    $test.equal ttGetText(el), 'Some text'

    scope.click()
    cd.scan ->
        $test.equal scope.name, 'Hello'
        $test.equal ttGetText(el), 'Hello'
        $test.close()
