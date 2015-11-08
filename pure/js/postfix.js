	/* prev prefix.js */
		return alight;
	}; // finish of buildAlight

	var alight = buildAlight();
	alight.makeInstance = buildAlight;
	// requrejs/commonjs
	if(typeof(define) === 'function') {
		define(function() {
			return alight;
		});
	} else if(typeof(module) === 'object' && typeof(module.exports) === 'object') {
		module.exports = alight
	} else if(typeof(alightInitCallback) === 'function') {
		alightInitCallback(alight)
	} else {
		window.alight = alight;
		alight.f$.ready(alight.bootstrap);
	};
})();
