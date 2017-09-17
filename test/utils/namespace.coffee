
Test('alight namespaces').run ($test, alight) ->
	$test.start 4
	ns = alight.namespace('ns')

	ns.controllers({
		test: () -> {}
	})

	$test.check alight.controllers.hasOwnProperty('nsTest')

	ns.directives({
		test:
				link: () -> {}
	})

	$test.check alight.directives.hasOwnProperty('ns')
	$test.check alight.directives.ns.hasOwnProperty('test')

	ns.filters({
		test: () -> {}
	})

	$test.check alight.filters.hasOwnProperty('nsTest')

	$test.close()
