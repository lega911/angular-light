
Test('al-css-1').run ($test, alight) ->
	$test.start 5

	el = document.createElement 'div'
	el.innerHTML = '<i class="aaa" al-css="bbb ccc ddd: active, fff eee: active2"></i>'
	tag = el.children[0]

	cd = alight tag,
		active: false
		active2: false
	scope = cd.scope

	result = ->
		if tag.classList
			l = Array.prototype.slice.call tag.classList
		else
			# <= IE9
			css = tag.className
			l = css.trim().split ' '
		l.sort().join ' '
	$test.equal result(), 'aaa'

	scope.active = true
	cd.scan ->
		$test.equal result(), 'aaa bbb ccc ddd'

		scope.active2 = true
		cd.scan ->
			$test.equal result(), 'aaa bbb ccc ddd eee fff'

			scope.active = false
			cd.scan ->
				$test.equal result(), 'aaa eee fff'

				scope.active2 = false
				cd.scan ->
					$test.equal result(), 'aaa'
					$test.close()


Test('directive-scope-isolate-0').run ($test, alight) ->
	$test.start 2

	alight.directives.ut =
		siTest1:
			template: '{{name}}:{{name2}}:{{ $parent.name}}:{{ $parent.name2}}'
			link: (scope,  el, name) ->
				scope.$parent = scope.$parent or scope
				scope.name2 = 'child1'
		siTest2:
			scope: true
			template: '{{name}}:{{name2}}:{{ $parent.name}}:{{ $parent.name2}}'
			link: (scope, el, name) ->
				scope.name2 = 'child2'

	el = document.createElement 'div'
	el.innerHTML = '<div id="i1" ut-si-test1></div><div id="i2" ut-si-test2></div>'

	scope = alight.bootstrap el,
		name: 'parent'

	f$ = alight.f$
	$test.equal ttGetText(f$_find(el, '#i1')[0]), 'parent:child1:parent:child1'
	$test.equal ttGetText(f$_find(el, '#i2')[0]), ':child2:parent:child1'
	$test.close()


Test('restrict-m-1').run ($test, alight) ->
	$test.start 1

	alight.directives.ut =
		test1:
			restrict: 'M'
			stopBinding: true
			init: (scope, element, value, env) ->
				scope.name = 'Hello'

				el = document.createElement 'p'
				el.innerHTML = "{{name}} #{value}"

				alight.f$.after element, el
				env.bind scope, el

	el = document.createElement 'div'
	el.innerHTML = "<div>
						<!-- directive: ut-test1 World!-->
					</div>"

	alight el

	$test.equal ttGetText(f$_find(el, 'p')[0]), 'Hello World!'
	$test.close()


Test('restrict-m-2').run ($test, alight) ->
	$test.start 1

	# init
	do ->
		alight.directives.ut =
			test2:
				restrict: 'M'
				template: "<p>{{name}} {{value}}!</p>"
				link: (scope, element, value) ->
					scope.name = 'Hello'
					scope.value = value

	# test
	do ->
		el = document.createElement 'div'
		el.innerHTML = "<div>
							<!-- directive: ut-test2 World-->
						</div>"

		alight.bootstrap el

		$test.equal ttGetText(f$_find(el, 'p')[0]), 'Hello World!'
		$test.close()


Test('al-ctrl-0').run ($test, alight) ->
	$test.start 3

	dom = $ '<div al-ctrl="foo"><i al-getter></i></div>'
	c0 = 0
	c1 = 0

	alight.ctrl.foo = (scope) ->
		c0++
		scope.value = 123

	alight.d.al.getter = (scope) ->
		c1++
		$test.equal scope.value, 123

	alight.bootstrap(dom[0])

	$test.equal c0, 1
	$test.equal c1, 1
	$test.close()


Test('al-value-on-off').run ($test, alight, timeout) ->
	if typeof(CustomEvent) isnt 'function'
		console.warn 'skip al-value on/off'
		return 'skip'

	$test.start 3

	dom = $ '<div><input type="text" al-value="name" /></div>'
	input = dom.find('input')[0]

	cd = alight input,
		name: '123'
	scope = cd.scope

	$test.equal input.value, '123'

	input.value = 'linux'
	input.dispatchEvent(new CustomEvent('input'))

	setTimeout ->
		$test.equal scope.name, 'linux'

		cd.destroy()

		input.value = 'macos'
		input.dispatchEvent(new CustomEvent('input'))

		setTimeout ->
			$test.equal scope.name, 'linux'
			$test.close()
		, 50
	, 50


Test('al-value-setter').run ($test, alight) ->
	if typeof(CustomEvent) isnt 'function'
		$test.close()
		console.warn 'skip al-value on/off'
		return

	$test.start 3

	dom = $ '<div><input type="text" al-value="name[0]" /></div>'
	input = dom.find('input')[0]

	cd = alight.bootstrap input,
		name: ['123']

	$test.equal input.value, '123'

	input.value = 'linux'
	input.dispatchEvent(new CustomEvent('input'))

	setTimeout ->
		$test.equal cd.scope.name[0], 'linux'

		input.value = 'new value'
		input.dispatchEvent(new CustomEvent('input'))

		setTimeout ->
			$test.equal cd.scope.name[0], 'new value'
			$test.close()
		, 50
	, 50


Test('al-text').run ($test, alight) ->
	$test.start 2

	el = ttDOM '<div al-text="name"></div>'

	cd = alight.bootstrap el,
		name: 'one'

	$test.equal ttGetText(el), 'one'

	cd.scope.name = 'two'
	cd.scan ->
		$test.equal ttGetText(el), 'two'

		$test.close()


Test 'al-stop'
	.run ($test, alight) ->
		$test.start 1

		el = ttDOM '<div>{{name}} <div al-stop>{{name}}</div> </div>'

		alight.bootstrap el,
			name: 'linux'

		$test.equal ttGetText(el), 'linux {{name}}'

		$test.close()


Test 'attr-class-0'
	.run ($test, alight) ->
		$test.start 6

		el = ttDOM '<span :class="custom"> </span><span :class.red.blue="v > 3"> </span>'

		cd = alight.ChangeDetector
			custom: 'green'
			v: 0

		alight.bind cd, el

		c = (n) ->
			el.childNodes[n].className or ''

		$test.equal c(0), 'green'
		$test.equal c(1).indexOf('red'), -1
		$test.equal c(1).indexOf('blue'), -1

		cd.scope.custom = 'one two'
		cd.scope.v = 5
		cd.scan()

		$test.equal c(0), 'one two'
		$test.equal c(1).indexOf('red') >= 0, true
		$test.equal c(1).indexOf('blue') >= 0, true

		$test.close()
