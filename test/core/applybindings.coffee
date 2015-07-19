
Test('apply_bindings', 'apply-binding-0').run ($test, alight) ->
    $test.start 12
    f$ = alight.f$

    el = document.createElement('div')
    count = 0
    scope = alight.Scope()
    scope.link = 'img.jpg'
    scope.redClass = false
    scope.testInit = ->
        count += 1

    f$.attr el, 'al-init', 'testInit()'
    f$.attr el, 'al-css', 'red: redClass'
    f$.attr el, 'al-src', 'some-{{link}}'
    f$.attr el, 'some-text', 'start:{{link}}:finish'
    alight.applyBindings scope, el

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
