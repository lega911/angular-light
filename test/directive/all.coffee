
Test('al-css-1', 'al-css-1').run ($test, alight) ->
	$test.start 5

	el = document.createElement 'div'
	el.innerHTML = '<i class="aaa" al-css="bbb ccc ddd: active, fff eee: active2"></i>'
	tag = el.children[0]

	scope = alight.bootstrap tag,
		active: false
		active2: false

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
	scope.$scan ->
		$test.equal result(), 'aaa bbb ccc ddd'

		scope.active2 = true
		scope.$scan ->
			$test.equal result(), 'aaa bbb ccc ddd eee fff'

			scope.active = false
			scope.$scan ->
				$test.equal result(), 'aaa eee fff'

				scope.active2 = false
				scope.$scan ->
					$test.equal result(), 'aaa'
					$test.close()


Test('directive-scope-isolate-0').run ($test, alight) ->
	$test.start 2

	alight.directives.ut =
		siTest1:
			template: '{{name}}:{{name2}}:{{$parent.name}}:{{$parent.name2}}'
			link: (scope,  el, name) ->
				scope.$parent = scope.$parent or scope
				scope.name2 = 'child1'
		siTest2:
			scope: 'isolate'
			template: '{{name}}:{{name2}}:{{$parent.name}}:{{$parent.name2}}'
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

	# init
	do ->
		alight.directives.ut =
			test1:
				restrict: 'M'
				stopBinding: true
				init: (scope, element, value) ->
					scope.name = 'Hello'

					el = document.createElement 'p'
					el.innerHTML = "{{name}} #{value}"

					alight.f$.after element, el
					alight.bind scope, el

	# test
	do ->
		el = document.createElement 'div'
		el.innerHTML = "<div>
							<!-- directive: ut-test1 World!-->
						</div>"

		alight.bootstrap el

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


Test('al-value-on-off', 'al-value-on-off').run ($test, alight, timeout) ->
	if typeof(CustomEvent) isnt 'function'
		$test.close()
		console.warn 'skip al-value on/off'
		return

	$test.start 3

	dom = $ '<div><input type="text" al-value="name" /></div>'
	input = dom.find('input')[0]

	scope = alight.bootstrap dom,
		name: '123'

	$test.equal input.value, '123'

	input.value = 'linux'
	input.dispatchEvent(new CustomEvent('input'))

	setTimeout ->
		$test.equal scope.name, 'linux'

		scope.$destroy()

		input.value = 'macos'
		input.dispatchEvent(new CustomEvent('input'))

		setTimeout ->
			$test.equal scope.name, 'linux'
			$test.close()
		, 50
	, 50


Test('al-value setter').run ($test, alight) ->
	if typeof(CustomEvent) isnt 'function'
		$test.close()
		console.warn 'skip al-value on/off'
		return

	$test.start 3

	dom = $ '<div><input type="text" al-value="name[0]" /></div>'
	input = dom.find('input')[0]

	scope = alight.bootstrap dom,
		name: ['123']

	$test.equal input.value, '123'

	input.value = 'linux'
	input.dispatchEvent(new CustomEvent('input'))

	setTimeout ->
		$test.equal scope.name[0], 'linux'

		input.value = 'new value'
		input.dispatchEvent(new CustomEvent('input'))

		setTimeout ->
			$test.equal scope.name[0], 'new value'
			$test.close()
		, 50
	, 50


Test('al-text').run ($test, alight) ->
	$test.start 2

	el = ttDOM '<div al-text="name"></div>'

	scope = alight.bootstrap el,
		name: 'one'

	$test.equal ttGetText(el), 'one'

	scope.name = 'two'
	scope.$scan ->
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
