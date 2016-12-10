
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
