
Test('event-0').run ($test, alight, timeout) ->
    if $test.isPhantom
        $test.skip 1
        $test.close()
        return

    $test.start 2

    el = ttDOM '''
        <div id="click" al-on.click="onClick($event)"></div>
    '''

    count = 0
    alight.bootstrap el,
        onClick: ->
            count++

    $test.equal count, 0

    event = new Event 'click'
    div = el.querySelector '#click'
    div.dispatchEvent event

    $test.equal count, 1
    $test.close()


Test('event-1').run ($test, alight, timeout) ->
    if $test.isPhantom
        $test.skip 1
        $test.close()
        return

    $test.start 10

    el = ttDOM '''
        <input id="input" al-on.keydown.13="onEnter($event)"  al-on.keydown="onKey($event)" />
    '''

    enterCount = 0
    keyCount = 0
    alight.bootstrap el,
        onEnter: ->
            enterCount++
        onKey: ->
            keyCount++

    input = el.querySelector '#input'
    dispatch = (code) ->
        event = new Event 'keydown'
        event.keyCode = code
        input.dispatchEvent event

    $test.equal enterCount, 0
    $test.equal keyCount, 0

    dispatch 32
    $test.equal enterCount, 0
    $test.equal keyCount, 1

    dispatch 40
    $test.equal enterCount, 0
    $test.equal keyCount, 2

    dispatch 13
    $test.equal enterCount, 1
    $test.equal keyCount, 3

    dispatch 48
    $test.equal enterCount, 1
    $test.equal keyCount, 4

    $test.close()
