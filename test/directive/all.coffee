
Test('al-css-1', 'al-css-1').run ($test, alight) ->
	$test.start 5

	el = document.createElement 'div'
	el.innerHTML = '<i class="aaa" al-css="bbb ccc ddd: active, fff eee: active2"></i>'
	tag = el.children[0]

	scope =
		active: false
		active2: false
	cd = alight.ChangeDetector scope

	alight.applyBindings cd, tag

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


Test('directive.scope isolate #0', 'directive-scope-isolate-0').run ($test, alight) ->
	$test.start 2

	alight.directives.ut =
		siTest1:
			template: '{{name}}:{{name2}}:{{$parent.name}}:{{$parent.name2}}'
			link: (cd, el, name) ->
				scope = cd.scope
				scope.$parent = scope.$parent or scope
				scope.name2 = 'child1'
		siTest2:
			scope: true
			template: '{{name}}:{{name2}}:{{$parent.name}}:{{$parent.name2}}'
			link: (cd, el, name) ->
				cd.scope.name2 = 'child2'

	scope =
		name: 'parent'
	cd = alight.ChangeDetector scope

	el = document.createElement 'div'
	el.innerHTML = '<div id="i1" ut-si-test1></div><div id="i2" ut-si-test2></div>'

	alight.applyBindings cd, el


	f$ = alight.f$
	$test.equal f$.text(f$.find(el, '#i1')[0]), 'parent:child1:parent:child1'
	$test.equal f$.text(f$.find(el, '#i2')[0]), ':child2:parent:child1'
	$test.close()


Test('restrict M #1').run ($test, alight) ->
	$test.start 1

	# init
	do ->
		alight.directives.ut =
			test1:
				restrict: 'M'
				init: (cd, element, value) ->
					cd.scope.name = 'Hello'

					el = document.createElement 'p'
					el.innerHTML = "{{name}} #{value}"

					alight.f$.after element, el
					alight.applyBindings cd, el

					owner: true

	# test
	do ->
		el = document.createElement 'div'
		el.innerHTML = "<div>
							<!-- directive: ut-test1 World!-->
						</div>"

		cd = alight.ChangeDetector()
		alight.applyBindings cd, el

		$test.equal alight.f$.text(alight.f$.find(el, 'p')[0]).trimLeft(), 'Hello World!'
		$test.close()


Test('restrict M #2', 'restrict-m-2').run ($test, alight) ->
	$test.start 1

	# init
	do ->
		alight.directives.ut =
			test2:
				restrict: 'M'
				template: "<p>{{name}} {{value}}!</p>"
				link: (cd, element, value) ->
					cd.scope.name = 'Hello'
					cd.scope.value = value

	# test
	do ->
		el = document.createElement 'div'
		el.innerHTML = "<div>
							<!-- directive: ut-test2 World-->
						</div>"

		cd = alight.ChangeDetector()
		alight.applyBindings cd, el

		$test.equal alight.f$.text(alight.f$.find(el, 'p')[0]).trimLeft(), 'Hello World!'
		$test.close()


Test('al-controller').run ($test, alight) ->
	$test.start 3

	dom = $ '<div ctrl-foo><i al-getter></i></div>'
	c0 = 0
	c1 = 0

	alight.d.ctrl.foo = (cd) ->
		c0++
		cd.scope.value = 123

	alight.directives.al.getter = (cd, el, name) ->
		c1++
		$test.equal cd.scope.value, 123

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
	scope =
		name: '123'
	cd = alight.ChangeDetector scope

	dom = $ '<div><input type="text" al-value="name" /></div>'
	input = dom.find('input')[0]

	alight.applyBindings cd, dom[0]

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


Test('al-value setter').run ($test, alight) ->
	if typeof(CustomEvent) isnt 'function'
		$test.close()
		console.warn 'skip al-value on/off'
		return

	$test.start 3
	scope =
		name: ['123']
	cd = alight.ChangeDetector scope

	dom = $ '<div><input type="text" al-value="name[0]" /></div>'
	input = dom.find('input')[0]

	alight.applyBindings cd, dom[0]

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

	scope =
		name: 'one'
	cd = alight.ChangeDetector scope

	el = $('<div al-text="name"></div>')[0]

	alight.applyBindings cd, el

	$test.equal el.innerText, 'one'

	scope.name = 'two'
	cd.scan ->
		$test.equal el.innerText, 'two'

		$test.close()
