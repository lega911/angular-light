
Test('dom-optimization-0').run ($test, alight) ->
    $test.start 24
    # text, value, filter, directive

    alight.text.print = (callback, text, scope, env) ->
        callback text.trim()

    test = (html, result) ->
        el = ttDOM html

        alight el,
            value0: 0
            double: (input) ->
                input + input

        $test.equal el.childNodes.length, result.length
        result.forEach (value, i) ->
            $test.equal el.childNodes[i].nodeValue, value

    test 'text', ['text']
    test "start {{value0}} end", ['start 0 end']
    test "start {{value0}} - {{double(2)}} end", ['start 0 - 4 end']
    test "start {{7 | double}} finish", ['start 14 finish']
    test "start {{value0}} - {{7 | double}} finish", ['start 0 - ', '14 finish']
    test "start {{5 | double}} - {{7 | double}} finish", ['start 10 - 14 finish']
    test "start {{#print echo}} finish", ['start echo finish']
    test "start {{#print Linux}} {{#print Ubuntu}} finish", ['start Linux Ubuntu finish']
    test "start {{value0}} {{#print go}} finish", ['start 0 ', 'go finish']
    test "start {{value0}} {{15 | double}} {{#print go}} finish", ['start 0 ', '30 ', 'go finish']

    $test.close()


Test('dom-optimization-1').run ($test, alight) ->
    $test.start 3

    el = document.createElement 'div'
    el.innerHTML = "  <p>123</p>  <div> <b> </b> </div>  "

    alight el

    $test.equal el.childNodes.length, 3
    $test.equal el.childNodes[2].childNodes.length, 1
    $test.equal el.childNodes[2].childNodes[0].childNodes.length, 0

    $test.close()



Test('dom-optimization-2').run ($test, alight) ->
    $test.start 3

    el = document.createElement 'tbody'
    el.innerHTML = "  <tr> <td> </td> <td> </td> </tr>   <tr> </tr>  "

    alight el

    $test.equal el.childNodes.length, 2
    $test.equal el.childNodes[0].childNodes.length, 2
    $test.equal el.childNodes[0].childNodes[0].childNodes.length, 0

    $test.close()



Test('dom-optimization-3').run ($test, alight) ->
    $test.start 3

    el = document.createElement 'pre'
    el.innerHTML = "  <p>123</p>  <div> <b> </b> </div>  "

    alight el

    $test.equal el.childNodes.length, 5
    $test.equal el.childNodes[3].childNodes.length, 3
    $test.equal el.childNodes[3].childNodes[1].childNodes.length, 1

    $test.close()
