	/* prev prefix.js */
		return alight;
	}; // finish of buildAlight

	// requrejs/commonjs
	if(typeof(define) === 'function') {
		define(function() {
			var alight = buildAlight();
			alight.makeInstance = buildAlight;
			return alight;
		});
	} else if(typeof(module) === 'object' && typeof(module.exports) === 'object') {
		var alight = buildAlight();
		alight.makeInstance = buildAlight;
		module.exports = alight;
	} else if(typeof(alightInitCallback) === 'function') {
		alightInitCallback(buildAlight)
	} else {
		var alight = buildAlight({
			globalControllers: true
		})

		window.alight = alight;
		window.f$ = alight.f$;
		f$.ready(alight.bootstrap);
	};
})();
