
###

watch ob, 'foo.bar', cb

ob.wtree =
	foo:
		$$cbs
		bar:
			$$cbs

tree =
	$$scope
	$$path

ensureObserve ob, key
scope.$$observer
	k1: tree
	k2: tree




###

alight.observer = self = {}
specWords =
	'$system': true
	'$parent': true
	'$ns': true
	'$$scope': true
	'$$path': true
	'$$isArray': true
	'$$observer': true
	'$$cbs': true


isObjectOrArray = (d) ->
	if f$.isObject d
		return true
	f$.isArray d


self.watch = (ob, key, callback) ->
	t = ob.wtree
	for k in key.split '.'
		if not t[k]
			t[k] =
				$$cbs: []
		t = t[k]
		t.$$cbs.push callback
	ensureObserve ob, key	
	callback


ensureObserve = (ob, key) ->
	scope = ob.scope
	tree = ob.tree

	kList = key.split '.'

	path = ''
	i = 0
	len = kList.length
	while i < len
		k = kList[i++]

		if len is i  # i was incremented
			if not f$.isArray scope[k]
				break
		else
			if not isObjectOrArray scope[k]
				break

		if not tree[k]
			tree[k] = {}
		tree = tree[k]

		if path
			path += '.' + k
		else
			path = k
		scope = scope[k]

		if not scope.$$observer
			scope.$$observer = {}

		if tree.$$scope
			continue

		tree.$$scope = scope
		tree.$$path = path
		scope.$$observer[ob.key] = tree
		if f$.isArray scope
			tree.$$isArray = true
			Array.observe scope, ob.handler
		else
			Object.observe scope, ob.handler
	null


ensureTree = (ob, key) ->
	wtree = ob.wtree

	for k in key.split '.'
		wtree = wtree[k]
		if not wtree
			break

	if wtree
		ensureTree2 ob, wtree, key


ensureTree2 = (ob, wtree, path) ->
	r = false
	for k of wtree
		if specWords[k]
			continue
		if ensureTree2 ob, wtree[k], "#{path}.#{k}"
			r = true

	if not r and wtree.$$cbs.length
		ensureObserve ob, path
		return true
	false


self.unwatch = (ob, key, callback) ->
	t = ob.wtree
	for k in key.split '.'
		c = t[k]
		if not c
			continue
		i = c.$$cbs.indexOf callback
		if i>= 0
			c.$$cbs.splice i, 1

		t = c
	null


fire = (wtree, key, value) ->
	t = wtree
	for k in key.split '.'
		t = t[k] or {}
	if t.$$cbs
		for cb in t.$$cbs
			cb value
	null


cleanTree = (ob, tree, checkingScope) ->
	if checkingScope and checkingScope isnt tree.$$scope
		console.error 'Observe: fake scope'
	scope = tree.$$scope

	if f$.isArray tree.$$scope
		tree.$$isArray = null
		Array.unobserve tree.$$scope, ob.handler
	else
		Object.unobserve tree.$$scope, ob.handler
	tree.$$scope.$$observer[ob.key] = null
	tree.$$scope = null
	tree.$$path = null
	for k, v of tree
		if specWords[k]
			continue
		if not f$.isObject v
			continue
		cleanTree ob, tree[k]
	null


self.observe = (rootScope, conf) ->
	conf = conf or {}
	ob =
		key: alight.utilits.getId()
		scope: rootScope
		tree: {}
		wtree: {}
		path: ''
		rootEvent: conf.rootEvent
		active: not conf.noActive
		handler: (changes) ->
			for ch in changes
				scope = ch.object
				if not scope.$$observer
					continue
				tree = scope.$$observer[ob.key]

				if tree.$$isArray
					fire ob.wtree, tree.$$path, null
				else
					key = ch.name
					if specWords[key]
						continue

					value = scope[key]

					if tree.$$path
						keyPath = "#{tree.$$path}.#{key}"
					else
						keyPath = key

					if ch.type is 'add'
						if isObjectOrArray value
							ensureTree ob, keyPath
						fire ob.wtree, keyPath, value
					else if ch.type is 'update'
						if tree[key] and isObjectOrArray ch.oldValue
							cleanTree ob, tree[key], ch.oldValue
						if isObjectOrArray value
							ensureTree ob, keyPath
						fire ob.wtree, keyPath, null
					else if ch.type is 'delete'
						if isObjectOrArray ch.oldValue
							cleanTree ob, tree[key], ch.oldValue
						fire ob.wtree, keyPath, null
					if tree is ob.tree
						ob.rootEvent keyPath, value
			null

	# set root observer
	do (scope=ob.scope, tree=ob.tree) ->
		if not scope.$$observer
			scope.$$observer = {}

		tree = ob.tree
		if not tree.$$scope
			tree.$$scope = scope
			tree.$$path = ''
			scope.$$observer[ob.key] = tree
			Object.observe scope, ob.handler
	
	ob


self.unobserve = (ob) ->
	cleanTree ob, ob.tree, ob.scope
	ob.scope = null
	ob.tree = null
	ob.wtree = null
	ob.rootEvent = null
	null


self.reobserve = (ob, key) ->
	if ob.tree[key]
		cleanTree ob, ob.tree[key]
	if isObjectOrArray ob.scope[key]
		ensureTree ob, key


self.fire = (ob, name) ->
	fire ob.wtree, name, null


self.deliver = (ob) ->
	Object.deliverChangeRecords ob.handler
