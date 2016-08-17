
Test('fast-binding-0').run ($test, alight) ->
    $test.start 14

    elBase = document.createElement 'div'
    elBase.innerHTML = '''
        root={{rootValue}}
        <span attr0="a{{attr0}}" attr1="value1" attr2="{{attr2}}a">child0={{child0}}</span>
        <span>no bind <b><b attr4="{{attr4}}x"></b></b> </span>
        <span attr3="a{{attr3}}a">{{child2}}-from-child</span>
    '''
    f$_attr elBase, 'attr5', 'y{{attr5}}'

    el = elBase.cloneNode true

    bindResult = alight.bind alight.ChangeDetector(), elBase

    cd = alight.ChangeDetector
        rootValue: 'unix'
        child0: 'linux'
        child2: 'ubuntu'
        attr0: '000'
        attr2: '222'
        attr3: '333'
        attr4: '444'
        attr5: '555'

    fb = alight.core.fastBinding bindResult
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

    cd = alight.ChangeDetector()
    scope = cd.scope
    scope.list = [
        {name: 'l', value: 5}
        {name: 'u', value: 7}
        {name: 'd', value: 11}
    ]
    scope.foo = (x) ->
        x*2

    alight.bind cd, el

    $test.equal ttGetText(el), 'a-l b-10 c-10 d-l e-ll ' + 'a-u b-14 c-14 d-u e-uu ' + 'a-d b-22 c-22 d-d e-dd'
    
    scope.list[1] =
        name: 'x'
        value: 3
    cd.scan()
    $test.equal ttGetText(el), 'a-l b-10 c-10 d-l e-ll ' + 'a-x b-6 c-6 d-x e-xx ' + 'a-d b-22 c-22 d-d e-dd'

    scope.list.push
        name: 'y'
        value: 9
    cd.scan()
    $test.equal ttGetText(el), 'a-l b-10 c-10 d-l e-ll ' + 'a-x b-6 c-6 d-x e-xx ' + 'a-d b-22 c-22 d-d e-dd ' + 'a-y b-18 c-18 d-y e-yy'

    $test.close()


Test('fast-binding-2').run ($test, alight) ->
    $test.start 4
    el = ttDOM """
        <select>
            <option al-repeat="it in list" value="{{it}}">{{it}} </option>
        </select>
    """

    cd = alight.bootstrap el,
        list: ['windows', 'mac', 'linux']

    $test.equal ttGetText(el), 'windows mac linux'
    $test.equal f$_find(el, 'option')[0].attributes.value.value, 'windows'
    $test.equal f$_find(el, 'option')[1].attributes.value.value, 'mac'
    $test.equal f$_find(el, 'option')[2].attributes.value.value, 'linux'

    $test.close()


Test('fast-binding-3').run ($test, alight) ->
    $test.start 13
    el = ttDOM """
        <one attr0="x{{a0}}" :title="a0">x{{t0}}</one>
        <two @click.ar.gu.me.nt="t1=5" attr1="x{{a1}}" :title="a1">x{{t1}}</two>
    """

    el2 = el.cloneNode true

    bindResult = alight.bind alight.ChangeDetector(), el
    fb = alight.core.fastBinding bindResult

    cd = alight.ChangeDetector
        a0: 'First'
        t0: 'One'
        a1: 'Second'
        t1: 'Two'

    fb.bind cd, el2
    cd.scan()

    $test.equal f$_find(el2, 'one')[0].attributes.attr0.value, 'xFirst'
    $test.equal f$_find(el2, 'one')[0].attributes.title.value, 'First'
    $test.equal f$_find(el2, 'one')[0].innerHTML, 'xOne'
    $test.equal f$_find(el2, 'two')[0].attributes.attr1.value, 'xSecond'
    $test.equal f$_find(el2, 'two')[0].attributes.title.value, 'Second'
    $test.equal f$_find(el2, 'two')[0].innerHTML, 'xTwo'

    cd.scope.a0 = 'Linux'
    cd.scope.t0 = 'Ubuntu'
    cd.scope.a1 = 'Debian'
    cd.scope.t1 = 'Unix'

    cd.scan()

    $test.equal f$_find(el2, 'one')[0].attributes.attr0.value, 'xLinux'
    $test.equal f$_find(el2, 'one')[0].attributes.title.value, 'Linux'
    $test.equal f$_find(el2, 'one')[0].innerHTML, 'xUbuntu'
    $test.equal f$_find(el2, 'two')[0].attributes.attr1.value, 'xDebian'
    $test.equal f$_find(el2, 'two')[0].attributes.title.value, 'Debian'
    $test.equal f$_find(el2, 'two')[0].innerHTML, 'xUnix'

    cd.scope.a0 = null
    cd.scan()
    $test.equal f$_find(el2, 'one')[0].attributes.title, undefined

    if window.CustomEvent
        $test.start 1
        event = new CustomEvent 'click'
        f$_find(el2, 'two')[0].dispatchEvent event

        $test.equal f$_find(el2, 'two')[0].innerHTML, 'x5'
    else
        $test.skip 1

    $test.close()


Test('fast-binding-4').run ($test, alight) ->
    if $test.isPhantom
        $test.skip 1
        $test.close()
        return

    $test.start 12

    if not alight.d.al.model
        alight.d.al.model = (scope, element, key, env) ->
            if element.type is 'checkbox'
                alight.d.al.checked.init.call @, scope, element, key, env
            else
                alight.d.al.value.init.call @, scope, element, key, env

    _el = ttDOM """
        <input type="text" al-model="a" />
        <input type="text" al-value="b" />
        <input type="checkbox" al-model="c" />
        <input type="checkbox" al-checked="d" />
    """

    el = _el.cloneNode true

    bindResult = alight.bind alight.ChangeDetector(), _el
    fb = alight.core.fastBinding bindResult

    cd = alight.ChangeDetector
        a: 'aaa'
        b: 'bbb'
        c: true
        d: true

    fb.bind cd, el
    cd.scan()

    $test.equal el.children[0].value, 'aaa'
    $test.equal el.children[1].value, 'bbb'
    $test.equal el.children[2].checked, true
    $test.equal el.children[3].checked, true

    cd.scope.a = 'ubuntu'
    cd.scope.b = 'linux'
    cd.scope.c = false
    cd.scope.d = false
    cd.scan()

    $test.equal el.children[0].value, 'ubuntu'
    $test.equal el.children[1].value, 'linux'
    $test.equal el.children[2].checked, false
    $test.equal el.children[3].checked, false

    el.children[0].value = 'one'
    el.children[0].dispatchEvent new Event 'change'
    el.children[1].value = 'two'
    el.children[1].dispatchEvent new Event 'change'

    el.children[2].checked = true
    el.children[2].dispatchEvent new Event 'change'

    el.children[3].checked = true
    el.children[3].dispatchEvent new Event 'change'

    $test.equal cd.scope.a, 'one'
    $test.equal cd.scope.b, 'two'
    $test.equal cd.scope.c, true
    $test.equal cd.scope.d, true

    $test.close()
