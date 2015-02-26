Test('binding: al-css + attr').run ($test, alight) ->
	$test.start 1

	scope = alight.Scope()
	scope.css = 'two'
	scope.three = true

	el = document.createElement 'div'
	el.innerHTML = '<span class="one {{css}}" al-css="three: three"></span>'
	tag = el.children[0]

	alight.applyBindings scope, tag

	$test.equal tag.className, 'one two three'
	$test.close()


Test('al-css #1').run ($test, alight) ->
	$test.start 5

	el = document.createElement 'div'
	el.innerHTML = '<i class="aaa" al-css="bbb ccc ddd: active, fff eee: active2"></i>'
	tag = el.children[0]

	scope = alight.Scope()
	scope.active = false
	scope.active2 = false

	alight.applyBindings scope, tag

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


Test('directive.scope isolate').run ($test, alight) ->
	$test.start 2

	alight.directives.ut =
		siTest1:
			scope: true
			template: '{{name}}:{{name2}}:{{$parent.name}}'
			link: (el, name, scope) ->
				scope.name2 = 'child1'
		siTest2:
			scope: 'isolate'
			template: '{{name}}:{{name2}}:{{$parent.name}}'
			link: (el, name, scope) ->
				scope.name2 = 'child2'

	scope = alight.Scope()
	scope.name = 'parent'

	el = document.createElement 'div'
	el.innerHTML = '<div id="i1" ut-si-test1></div><div id="i2" ut-si-test2></div>'

	alight.applyBindings scope, el


	f$ = alight.f$
	$test.equal f$.text(f$.find(el, '#i1')[0]), 'parent:child1:parent'
	$test.equal f$.text(f$.find(el, '#i2')[0]), ':child2:parent'
	$test.close()


Test('restrict M #1').run ($test, alight) ->
	$test.start 1

	# init
	do ->
		alight.directives.ut =
			test1:
				restrict: 'M'
				init: (element, value, scope) ->
					scope.name = 'Hello'

					el = document.createElement 'p'
					el.innerHTML = "{{name}} #{value}"

					alight.f$.after element, el

					child = scope.$new()
					alight.applyBindings scope, el

					{ owner: true }

	# test
	do ->
		el = document.createElement 'div'
		el.innerHTML = "<div>
							<!-- directive: ut-test1 World!-->
						</div>"

		scope = alight.Scope()
		alight.applyBindings scope, el

		$test.equal alight.f$.text(alight.f$.find(el, 'p')[0]).trimLeft(), 'Hello World!'
		$test.close()


Test('restrict M #2').run ($test, alight) ->
	$test.start 1

	# init
	do ->
		alight.directives.ut =
			test2:
				restrict: 'M'
				template: "<p>{{name}} {{value}}!</p>"
				link: (element, value, scope) ->
					scope.name = 'Hello'
					scope.value = value

	# test
	do ->
		el = document.createElement 'div'
		el.innerHTML = "<div>
							<!-- directive: ut-test2 World-->
						</div>"

		scope = alight.Scope()
		alight.applyBindings scope, el

		$test.equal alight.f$.text(alight.f$.find(el, 'p')[0]).trimLeft(), 'Hello World!'
		$test.close()
