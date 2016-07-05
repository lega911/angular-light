
Test('fast-binding 0', 'fast-binding-0').run ($test, alight) ->
    $test.start 14

    el = document.createElement 'div'
    el.innerHTML = '''
        root={{rootValue}}
        <span attr0="a{{attr0}}" attr1="value1" attr2="{{attr2}}a">child0={{child0}}</span>
        <span>no bind <b><b attr4="{{attr4}}x"></b></b> </span>
        <span attr3="a{{attr3}}a">{{child2}}-from-child</span>
    '''
    f$_attr el, 'attr5', 'y{{attr5}}'

    cd = alight.ChangeDetector
        rootValue: 'unix'
        child0: 'linux'
        child2: 'ubuntu'
        attr0: '000'
        attr2: '222'
        attr3: '333'
        attr4: '444'
        attr5: '555'

    fb = new alight.core.fastBinding el
    fb.bind cd, el

    $test.equal ttGetText(el), 'root=unix child0=linux no bind ubuntu-from-child'
    $test.equal el.childNodes[1].attributes.attr0.value, 'a000'
    $test.equal el.childNodes[1].attributes.attr1.value, 'value1'
    $test.equal el.childNodes[1].attributes.attr2.value, '222a'
    $test.equal el.childNodes[5].attributes.attr3.value, 'a333a'
    $test.equal el.childNodes[3].childNodes[1].childNodes[0].attributes.attr4.value, '444x'
    $test.equal el.attributes.attr5.value, 'y555'

    cd.scope.rootValue = 'new one'
    cd.scope.child2 = 'second'
    cd.scope.attr0 = 'first'
    cd.scope.attr2 = 'second'
    cd.scope.attr3 = 'third'
    cd.scope.attr4 = 'fourth'
    cd.scope.attr5 = 'fifth'
    cd.scan ->

        $test.equal ttGetText(el), 'root=new one child0=linux no bind second-from-child'
        $test.equal el.childNodes[1].attributes.attr0.value, 'afirst'
        $test.equal el.childNodes[1].attributes.attr1.value, 'value1'
        $test.equal el.childNodes[1].attributes.attr2.value, 'seconda'
        $test.equal el.childNodes[5].attributes.attr3.value, 'athirda'
        $test.equal el.childNodes[3].childNodes[1].childNodes[0].attributes.attr4.value, 'fourthx'
        $test.equal el.attributes.attr5.value, 'yfifth'
        $test.close()


Test('fast-binding-1').run ($test, alight) ->
    $test.start 3

    el = ttDOM """
        <div al-repeat="it in list">
            <i>a-{{it.name}}</i>
            <i>b-{{foo(it.value)}}</i>
            <i>c-{{it.value | double}}</i>
            <i>d-{{=it.name}}</i>
            <i>e-{{#dd it.name}}</i>
        </div>
    """

    alight.filters.double = (x) ->
        x*2

    alight.text.dd = (callback, expression, scope, env) ->
        value = env.changeDetector.eval expression
        env.setter value+value

    scope = alight.Scope()
    scope.list = [
        {name: 'l', value: 5}
        {name: 'u', value: 7}
        {name: 'd', value: 11}
    ]
    scope.foo = (x) ->
        x*2

    alight.bind scope, el

    $test.equal ttGetText(el), 'a-l b-10 c-10 d-l e-ll ' + 'a-u b-14 c-14 d-u e-uu ' + 'a-d b-22 c-22 d-d e-dd'
    
    scope.list[1] =
        name: 'x'
        value: 3
    scope.$scan()
    $test.equal ttGetText(el), 'a-l b-10 c-10 d-l e-ll ' + 'a-x b-6 c-6 d-x e-xx ' + 'a-d b-22 c-22 d-d e-dd'

    scope.list.push
        name: 'y'
        value: 9
    scope.$scan()
    $test.equal ttGetText(el), 'a-l b-10 c-10 d-l e-ll ' + 'a-x b-6 c-6 d-x e-xx ' + 'a-d b-22 c-22 d-d e-dd ' + 'a-y b-18 c-18 d-y e-yy'

    $test.close()


Test('fast-binding-2').run ($test, alight) ->
    $test.start 4
    el = ttDOM """
        <select>
            <option al-repeat="it in list" value="{{it}}">{{it}} </option>
        </select
    """

    cd = alight.bootstrap el,
        list: ['windows', 'mac', 'linux']

    $test.equal ttGetText(el), 'windows mac linux'
    $test.equal f$_find(el, 'option')[0].attributes.value.value, 'windows'
    $test.equal f$_find(el, 'option')[1].attributes.value.value, 'mac'
    $test.equal f$_find(el, 'option')[2].attributes.value.value, 'linux'

    $test.close()
