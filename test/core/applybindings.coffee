
Test('apply-binding-0').run ($test, alight) ->
    $test.start 12
    f$ = alight.f$

    el = document.createElement('div')
    f$.attr el, 'al-init', 'testInit()'
    f$.attr el, 'al-css', 'red: redClass'
    f$.attr el, 'al-src', 'some-{{link}}'
    f$.attr el, 'some-text', 'start:{{link}}:finish'

    count = 0
    scope = alight.bootstrap el,
        link: 'img.jpg'
        redClass: false
        testInit: ->
            count += 1

    $test.equal el.className, ''
    $test.equal f$.attr el, 'src', 'some-img.jpg'
    $test.equal count, 1
    $test.equal f$.attr el, 'some-text', 'start:img.jpg:finish'

    scope.$scan ->
        $test.equal el.className, ''
        $test.equal f$.attr el, 'src', 'some-img.jpg'
        $test.equal count, 1
        $test.equal f$.attr el, 'some-text', 'start:img.jpg:finish'

        scope.redClass = true
        scope.link = 'other.png'
        scope.$scan ->
            $test.equal el.className, 'red'
            $test.equal f$.attr el, 'src', 'some-other.png'
            $test.equal count, 1
            $test.equal f$.attr el, 'some-text', 'start:other.png:finish'

            $test.close()


Test('bootstrap-el').run ($test, alight) ->
    $test.start 4

    el = ttDOM "<div>{{name}}</div>"

    scope = alight.bootstrap el,
        name: 'Some text'
        click: ->
            @.name = 'Hello'

    $test.equal scope.name, 'Some text'
    $test.equal ttGetText(el), 'Some text'

    scope.click()
    scope.$scan ->
        $test.equal scope.name, 'Hello'
        $test.equal ttGetText(el), 'Hello'
        $test.close()
