
Test('apply-binding-0').run ($test, alight) ->
    $test.start 12
    f$ = alight.f$

    el = document.createElement('div')
    f$_attr el, 'al-init', 'testInit()'
    f$_attr el, ':class.red', 'redClass'
    f$_attr el, ':src.tpl', 'some-{{link}}'
    f$_attr el, 'some-text', 'start:{{link}}:finish'

    count = 0
    cd = alight.bootstrap el,
        link: 'img.jpg'
        redClass: false
        testInit: ->
            count += 1
    scope = cd.scope

    $test.equal el.className, ''
    $test.equal f$_attr el, 'src', 'some-img.jpg'
    $test.equal count, 1
    $test.equal f$_attr el, 'some-text', 'start:img.jpg:finish'

    cd.scan ->
        $test.equal el.className, ''
        $test.equal f$_attr el, 'src', 'some-img.jpg'
        $test.equal count, 1
        $test.equal f$_attr el, 'some-text', 'start:img.jpg:finish'

        scope.redClass = true
        scope.link = 'other.png'
        cd.scan ->
            $test.equal el.className.trim(), 'red'
            $test.equal f$_attr el, 'src', 'some-other.png'
            $test.equal count, 1
            $test.equal f$_attr el, 'some-text', 'start:other.png:finish'

            $test.close()


Test('bootstrap-el').run ($test, alight) ->
    if $test.basis
        return 'skip'
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


Test('stop-binding-2').run ($test, alight) ->
    $test.start 6

    run = ->
        el = ttDOM '''
            <div al-test>
                name={{$parent.name}}
            </div>
        '''

        root = alight.ChangeDetector
            name: 'root'

        alight.bind root, el

        ttGetText el

    count = 0
    alight.d.al.test =
        scope: true
        link: ->
            count++
    $test.equal run(), 'name=root'
    $test.equal count, 1

    alight.d.al.test =
        stopBinding: true
        scope: true
        link: ->
            count++
    $test.equal run(), 'name={{$parent.name}}'
    $test.equal count, 2

    alight.d.al.test =
        scope: true
        link: (scope, el, val, env) ->
            env.stopBinding = true
            count++
    $test.equal run(), 'name={{$parent.name}}'
    $test.equal count, 3

    $test.close()
